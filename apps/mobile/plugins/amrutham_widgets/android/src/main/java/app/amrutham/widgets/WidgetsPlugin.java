package app.amrutham.widgets;

import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import androidx.annotation.NonNull;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

/**
 * Bridge between the app and the home screen emergency cards. A plugin, not
 * MainActivity code, so it is registered in every Flutter engine (including a
 * background one) and can update the widgets from there.
 */
public class WidgetsPlugin
        implements FlutterPlugin,
                MethodChannel.MethodCallHandler,
                ActivityAware,
                PluginRegistry.NewIntentListener {
    private MethodChannel channel;
    private Context context;
    private ActivityPluginBinding activity;
    private Map<String, String> launchAction;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "app.amrutham/widgets");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding;
        binding.addOnNewIntentListener(this);
        launchAction = actionOf(binding.getActivity().getIntent());
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding;
        binding.addOnNewIntentListener(this);
    }

    @Override
    public void onDetachedFromActivity() {
        if (activity != null) activity.removeOnNewIntentListener(this);
        activity = null;
    }

    @Override
    public boolean onNewIntent(@NonNull Intent intent) {
        Map<String, String> action = actionOf(intent);
        if (action != null && channel != null) channel.invokeMethod("onAction", action);
        return action != null;
    }

    /** The action a widget tap carried, taken off the intent so it is not replayed. */
    private static Map<String, String> actionOf(Intent intent) {
        if (intent == null) return null;
        String action = intent.getStringExtra(EmergencyWidgetProvider.EXTRA_ACTION);
        String person = intent.getStringExtra(EmergencyWidgetProvider.EXTRA_PERSON);
        if (action == null) return null;
        intent.removeExtra(EmergencyWidgetProvider.EXTRA_ACTION);
        intent.removeExtra(EmergencyWidgetProvider.EXTRA_PERSON);
        Map<String, String> m = new HashMap<>();
        m.put("action", action);
        if (person != null) m.put("personId", person);
        return m;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            switch (call.method) {
                case "sync": {
                    boolean enabled = Boolean.TRUE.equals(call.argument("enabled"));
                    List<Map<String, Object>> people = call.argument("people");
                    Map<String, String> snapshots = call.argument("snapshots");
                    JSONArray array = new JSONArray();
                    if (people != null) {
                        for (Map<String, Object> p : people) array.put(new JSONObject(p));
                    }
                    WidgetStore.replace(context, enabled, array.toString(),
                            snapshots == null ? new HashMap<String, String>() : snapshots);
                    EmergencyWidgetProvider.updateAll(context);
                    result.success(null);
                    break;
                }
                case "cardCounts": {
                    AppWidgetManager manager = AppWidgetManager.getInstance(context);
                    int[] ids = manager.getAppWidgetIds(new ComponentName(context, EmergencyWidgetProvider.class));
                    Map<String, Integer> counts = new HashMap<>();
                    for (int id : ids) {
                        String person = WidgetStore.personFor(context, id);
                        if (person != null) {
                            Integer n = counts.get(person);
                            counts.put(person, n == null ? 1 : n + 1);
                        }
                    }
                    result.success(counts);
                    break;
                }
                case "pinCard": {
                    AppWidgetManager manager = AppWidgetManager.getInstance(context);
                    String personId = call.argument("personId");
                    if (personId == null || Build.VERSION.SDK_INT < 26 || !manager.isRequestPinAppWidgetSupported()) {
                        result.success(false);
                        break;
                    }
                    WidgetStore.setPending(context, personId);
                    result.success(manager.requestPinAppWidget(
                            new ComponentName(context, EmergencyWidgetProvider.class), null, null));
                    break;
                }
                case "initialAction": {
                    Map<String, String> action = launchAction;
                    launchAction = null;
                    result.success(action);
                    break;
                }
                default:
                    result.notImplemented();
            }
        } catch (Exception e) {
            result.error("widgets", e.getClass().getSimpleName(), null);
        }
    }
}
