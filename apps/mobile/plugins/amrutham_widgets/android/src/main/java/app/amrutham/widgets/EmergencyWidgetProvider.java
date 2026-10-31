package app.amrutham.widgets;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.util.SizeF;
import android.view.View;
import android.widget.RemoteViews;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

/** One emergency card. Each card shows one person, chosen when it was added. */
public class EmergencyWidgetProvider extends AppWidgetProvider {
    static final String EXTRA_ACTION = "amrutham_action";
    static final String EXTRA_PERSON = "amrutham_person";

    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        for (int id : ids) {
            // A card added from the app arrives here without a person: give it
            // the one the app just asked for.
            if (WidgetStore.personFor(context, id) == null) {
                String pending = WidgetStore.takePending(context);
                if (pending != null) WidgetStore.setPerson(context, id, pending);
            }
            manager.updateAppWidget(id, render(context, id));
        }
    }

    @Override
    public void onDeleted(Context context, int[] ids) {
        for (int id : ids) WidgetStore.forget(context, id);
    }

    static void updateAll(Context context) {
        AppWidgetManager manager = AppWidgetManager.getInstance(context);
        int[] ids = manager.getAppWidgetIds(new ComponentName(context, EmergencyWidgetProvider.class));
        for (int id : ids) manager.updateAppWidget(id, render(context, id));
    }

    /** Android 12+ chooses the large layout when the card is placed large. */
    static RemoteViews render(Context context, int widgetId) {
        RemoteViews compact = build(context, widgetId, R.layout.amrutham_emergency_widget);
        if (Build.VERSION.SDK_INT < 31) return compact;
        Map<SizeF, RemoteViews> bySize = new HashMap<>();
        bySize.put(new SizeF(110f, 110f), compact);
        bySize.put(new SizeF(250f, 160f), build(context, widgetId, R.layout.amrutham_emergency_widget_large));
        return new RemoteViews(bySize);
    }

    private static RemoteViews build(Context context, int widgetId, int layout) {
        RemoteViews v = new RemoteViews(context.getPackageName(), layout);
        int[] fields = {
            R.id.amrutham_name, R.id.amrutham_blood_tile, R.id.amrutham_blood_note,
            R.id.amrutham_allergies, R.id.amrutham_medicines, R.id.amrutham_message,
            R.id.amrutham_dial,
        };
        for (int f : fields) v.setViewVisibility(f, View.GONE);

        String personId = WidgetStore.personFor(context, widgetId);
        if (!WidgetStore.enabled(context)) {
            return message(context, v, widgetId, "Switched off. Turn on in Amrutham, Settings, Home screen widgets.", openApp(context, widgetId, null));
        }
        if (personId == null) {
            return message(context, v, widgetId, "Tap to choose who this card is for.", configure(context, widgetId));
        }
        String json = WidgetStore.snapshot(context, personId);
        if (json == null) {
            return message(context, v, widgetId, "Open Amrutham to refresh this card.", openApp(context, widgetId, personId));
        }
        try {
            JSONObject s = new JSONObject(json);
            v.setViewVisibility(R.id.amrutham_name, View.VISIBLE);
            v.setTextViewText(R.id.amrutham_name, s.optString("name", ""));
            if (!s.isNull("blood")) {
                v.setViewVisibility(R.id.amrutham_blood_tile, View.VISIBLE);
                v.setTextViewText(R.id.amrutham_blood, s.optString("blood", ""));
                v.setContentDescription(R.id.amrutham_blood_tile, "Blood group " + s.optString("blood", ""));
            }
            show(v, R.id.amrutham_blood_note, s, "bloodNote");
            show(v, R.id.amrutham_allergies, s, "allergies");
            show(v, R.id.amrutham_medicines, s, "medicines");
            JSONObject dial = s.optJSONObject("dial");
            if (dial != null) {
                v.setViewVisibility(R.id.amrutham_dial, View.VISIBLE);
                v.setTextViewText(R.id.amrutham_dial, "Dial " + dial.optString("label", ""));
                Intent call = new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + Uri.encode(dial.optString("number", ""))));
                v.setOnClickPendingIntent(R.id.amrutham_dial, PendingIntent.getActivity(
                        context, widgetId * 2 + 1, call, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT));
            }
            v.setOnClickPendingIntent(R.id.amrutham_root, openApp(context, widgetId, personId));
            v.setContentDescription(R.id.amrutham_root, "Emergency card for " + s.optString("name", ""));
        } catch (Exception e) {
            return message(context, v, widgetId, "Open Amrutham to refresh this card.", openApp(context, widgetId, personId));
        }
        return v;
    }

    private static void show(RemoteViews v, int id, JSONObject s, String key) {
        String text = s.isNull(key) ? null : s.optString(key, null);
        if (text == null || text.isEmpty()) return;
        v.setViewVisibility(id, View.VISIBLE);
        v.setTextViewText(id, text);
    }

    private static RemoteViews message(Context context, RemoteViews v, int widgetId, String text, PendingIntent tap) {
        v.setViewVisibility(R.id.amrutham_message, View.VISIBLE);
        v.setTextViewText(R.id.amrutham_message, text);
        v.setOnClickPendingIntent(R.id.amrutham_root, tap);
        return v;
    }

    private static PendingIntent openApp(Context context, int widgetId, String personId) {
        Intent launch = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
        if (launch == null) launch = new Intent();
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        if (personId != null) {
            launch.putExtra(EXTRA_ACTION, "emergency");
            launch.putExtra(EXTRA_PERSON, personId);
        }
        return PendingIntent.getActivity(context, widgetId * 2, launch,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
    }

    private static PendingIntent configure(Context context, int widgetId) {
        Intent i = new Intent(context, CardConfigActivity.class);
        i.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId);
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return PendingIntent.getActivity(context, widgetId * 2, i,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
    }
}
