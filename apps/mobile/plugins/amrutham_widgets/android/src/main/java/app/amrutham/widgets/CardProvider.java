package app.amrutham.widgets;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.RemoteViews;

import org.json.JSONObject;

/**
 * Shared by the three home screen widgets (the full card, a dial button, and
 * blood group with allergies). Each placed widget shows one person, chosen when
 * it was added; they all read the same small copy the app keeps.
 */
public abstract class CardProvider extends AppWidgetProvider {
    static final String EXTRA_ACTION = "amrutham_action";
    static final String EXTRA_PERSON = "amrutham_person";

    /** Every widget class this plugin ships, so a change reaches all of them. */
    static final Class<?>[] ALL = {
        EmergencyWidgetProvider.class, DialWidgetProvider.class, BloodWidgetProvider.class,
    };

    abstract RemoteViews render(Context context, AppWidgetManager manager, int widgetId);

    /** Fills the views for a person's snapshot. Only called when there is one. */
    abstract void fill(Context context, RemoteViews v, int widgetId, String personId, JSONObject snapshot) throws Exception;

    /** The views to hide first, so a state that fills nothing leaves nothing behind. */
    abstract int[] fields();

    abstract int layout(Context context, AppWidgetManager manager, int widgetId);

    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        for (int id : ids) {
            // A widget added from the app arrives without a person: give it the
            // one the app just asked for.
            if (WidgetStore.personFor(context, id) == null) {
                String pending = WidgetStore.takePending(context);
                if (pending != null) WidgetStore.setPerson(context, id, pending);
            }
            manager.updateAppWidget(id, render(context, manager, id));
        }
    }

    @Override
    public void onAppWidgetOptionsChanged(Context context, AppWidgetManager manager, int id, Bundle options) {
        manager.updateAppWidget(id, render(context, manager, id));
    }

    @Override
    public void onDeleted(Context context, int[] ids) {
        for (int id : ids) WidgetStore.forget(context, id);
    }

    static void updateAll(Context context) {
        AppWidgetManager manager = AppWidgetManager.getInstance(context);
        for (Class<?> c : ALL) {
            int[] ids = manager.getAppWidgetIds(new ComponentName(context, c));
            if (ids.length == 0) continue;
            try {
                CardProvider p = (CardProvider) c.getDeclaredConstructor().newInstance();
                for (int id : ids) manager.updateAppWidget(id, p.render(context, manager, id));
            } catch (Exception ignored) {
                // A widget that can't be drawn is left as it was.
            }
        }
    }

    /** Draws whichever state applies: off, no person, no copy yet, or the card. */
    RemoteViews build(Context context, AppWidgetManager manager, int widgetId) {
        RemoteViews v = new RemoteViews(context.getPackageName(), layout(context, manager, widgetId));
        for (int f : fields()) v.setViewVisibility(f, View.GONE);
        String personId = WidgetStore.personFor(context, widgetId);
        if (!WidgetStore.enabled(context)) {
            return message(v, "Switched off. Turn on in Amrutham, Settings, Home screen widgets.", openApp(context, widgetId, null));
        }
        if (personId == null) {
            return message(v, "Tap to choose who this is for.", configure(context, widgetId));
        }
        String json = WidgetStore.snapshot(context, personId);
        if (json == null) {
            return message(v, "Open Amrutham to refresh.", openApp(context, widgetId, personId));
        }
        try {
            fill(context, v, widgetId, personId, new JSONObject(json));
        } catch (Exception e) {
            return message(v, "Open Amrutham to refresh.", openApp(context, widgetId, personId));
        }
        return v;
    }

    static RemoteViews message(RemoteViews v, String text, PendingIntent tap) {
        v.setViewVisibility(R.id.amrutham_message, View.VISIBLE);
        v.setTextViewText(R.id.amrutham_message, text);
        v.setOnClickPendingIntent(R.id.amrutham_root, tap);
        return v;
    }

    static void show(RemoteViews v, int id, JSONObject s, String key) {
        String text = s.isNull(key) ? null : s.optString(key, null);
        if (text == null || text.isEmpty()) return;
        v.setViewVisibility(id, View.VISIBLE);
        v.setTextViewText(id, text);
    }

    static PendingIntent dial(Context context, int widgetId, JSONObject dial) {
        Intent call = new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + Uri.encode(dial.optString("number", ""))));
        return PendingIntent.getActivity(context, widgetId * 2 + 1, call,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
    }

    static PendingIntent openApp(Context context, int widgetId, String personId) {
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

    static PendingIntent configure(Context context, int widgetId) {
        Intent i = new Intent(context, CardConfigActivity.class);
        i.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId);
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return PendingIntent.getActivity(context, widgetId * 2, i,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
    }
}
