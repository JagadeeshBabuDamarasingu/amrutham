package app.amrutham

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

/**
 * Backup folder access through Android's document tree. Since Android 11 an app
 * cannot write plain file paths in shared storage, so the person picks a folder
 * once, the app keeps that permission, and writes go through the content
 * resolver.
 */
class MainActivity : FlutterActivity() {
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.amrutham/folder")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pick" -> pick(result)
                    "write" -> write(
                        call.argument<String>("tree")!!,
                        call.argument<String>("name")!!,
                        call.argument<ByteArray>("bytes")!!,
                        result,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun pick(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "A folder picker is already open", null)
            return
        }
        pendingPick = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
        )
        startActivityForResult(intent, PICK_FOLDER)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != PICK_FOLDER) {
            @Suppress("DEPRECATION")
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingPick
        pendingPick = null
        val uri = data?.data
        if (resultCode == Activity.RESULT_OK && uri != null) {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            result?.success(uri.toString())
        } else {
            result?.success(null)
        }
    }

    /** Writes [name] into the picked folder, replacing a file of the same name. */
    private fun write(tree: String, name: String, bytes: ByteArray, result: MethodChannel.Result) {
        thread {
            try {
                val treeUri = Uri.parse(tree)
                val dirId = DocumentsContract.getTreeDocumentId(treeUri)
                val dirUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, dirId)
                val target = findChild(treeUri, dirId, name)
                    ?: DocumentsContract.createDocument(
                        contentResolver, dirUri, "application/octet-stream", name,
                    )
                    ?: throw IllegalStateException("Could not create $name")
                contentResolver.openOutputStream(target, "wt")!!.use { it.write(bytes) }
                runOnUiThread { result.success(true) }
            } catch (e: Exception) {
                runOnUiThread { result.error("write_failed", e.message, null) }
            }
        }
    }

    private fun findChild(tree: Uri, dirId: String, name: String): Uri? {
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, dirId)
        val columns = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        )
        contentResolver.query(children, columns, null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                if (cursor.getString(1) == name) {
                    return DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(0))
                }
            }
        }
        return null
    }

    private companion object {
        const val PICK_FOLDER = 4711
    }
}
