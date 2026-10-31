package app.amrutham.folder;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.DocumentsContract;

import androidx.annotation.NonNull;

import java.io.OutputStream;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

/**
 * Backup folder access through Android's document tree. Since Android 11 an app
 * cannot write plain file paths in shared storage, so the person picks a folder
 * once, the app keeps that permission, and writes go through the content
 * resolver. Writing needs only a Context, so it also works in a background
 * task; picking needs the activity.
 */
public class FolderPlugin
        implements FlutterPlugin,
                MethodChannel.MethodCallHandler,
                ActivityAware,
                PluginRegistry.ActivityResultListener {
    private static final int PICK_FOLDER = 4711;

    private MethodChannel channel;
    private Context context;
    private ActivityPluginBinding activity;
    private MethodChannel.Result pendingPick;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "app.amrutham/folder");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
        executor.shutdown();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "pick":
                pick(result);
                break;
            case "write":
                write(call.<String>argument("tree"), call.<String>argument("name"),
                        call.<byte[]>argument("bytes"), result);
                break;
            default:
                result.notImplemented();
        }
    }

    private void pick(MethodChannel.Result result) {
        if (activity == null) {
            result.error("no_activity", "Open the app to choose a folder", null);
            return;
        }
        if (pendingPick != null) {
            result.error("busy", "A folder picker is already open", null);
            return;
        }
        pendingPick = result;
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION
                        | Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
        activity.getActivity().startActivityForResult(intent, PICK_FOLDER);
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != PICK_FOLDER) return false;
        MethodChannel.Result result = pendingPick;
        pendingPick = null;
        Uri uri = data == null ? null : data.getData();
        if (result == null) return true;
        if (resultCode == Activity.RESULT_OK && uri != null) {
            context.getContentResolver().takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
            result.success(uri.toString());
        } else {
            result.success(null);
        }
        return true;
    }

    /** Writes [name] into the picked folder, replacing a file of the same name. */
    private void write(String tree, String name, byte[] bytes, MethodChannel.Result result) {
        executor.execute(() -> {
            try {
                ContentResolver resolver = context.getContentResolver();
                Uri treeUri = Uri.parse(tree);
                String dirId = DocumentsContract.getTreeDocumentId(treeUri);
                Uri dirUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, dirId);
                Uri target = findChild(resolver, treeUri, dirId, name);
                if (target == null) {
                    target = DocumentsContract.createDocument(
                            resolver, dirUri, "application/octet-stream", name);
                }
                if (target == null) throw new IllegalStateException("Could not create " + name);
                try (OutputStream out = resolver.openOutputStream(target, "wt")) {
                    if (out == null) throw new IllegalStateException("Could not open " + name);
                    out.write(bytes);
                }
                main.post(() -> result.success(true));
            } catch (Exception e) {
                main.post(() -> result.error("write_failed", e.getMessage(), null));
            }
        });
    }

    private Uri findChild(ContentResolver resolver, Uri tree, String dirId, String name) {
        Uri children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, dirId);
        String[] columns = {
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        };
        try (Cursor cursor = resolver.query(children, columns, null, null, null)) {
            while (cursor != null && cursor.moveToNext()) {
                if (name.equals(cursor.getString(1))) {
                    return DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(0));
                }
            }
        }
        return null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding;
        binding.addActivityResultListener(this);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        if (activity != null) activity.removeActivityResultListener(this);
        activity = null;
    }
}
