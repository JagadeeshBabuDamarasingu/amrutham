package app.amrutham.widgets;

import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.os.Bundle;
import android.view.View;
import android.widget.RemoteViews;

import org.json.JSONObject;

/** The full card: name, blood group, allergies, medicines and a dial button. */
public class EmergencyWidgetProvider extends CardProvider {
    @Override
    RemoteViews render(Context context, AppWidgetManager manager, int widgetId) {
        return build(context, manager, widgetId);
    }

    @Override
    int[] fields() {
        return new int[] {
            R.id.amrutham_name, R.id.amrutham_blood_tile, R.id.amrutham_blood_note,
            R.id.amrutham_allergies, R.id.amrutham_medicines, R.id.amrutham_message,
            R.id.amrutham_dial,
        };
    }

    /**
     * The large layout when the card is placed large. The size comes from the
     * widget's own options, which every launcher reports; Android 12's
     * size-keyed layouts are not used because some launchers draw nothing for
     * them.
     */
    @Override
    int layout(Context context, AppWidgetManager manager, int widgetId) {
        Bundle o = manager.getAppWidgetOptions(widgetId);
        int w = o == null ? 0 : o.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0);
        int h = o == null ? 0 : o.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0);
        return w >= 240 && h >= 150 ? R.layout.amrutham_emergency_widget_large : R.layout.amrutham_emergency_widget;
    }

    @Override
    void fill(Context context, RemoteViews v, int widgetId, String personId, JSONObject s) {
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
            v.setOnClickPendingIntent(R.id.amrutham_dial, dial(context, widgetId, dial));
        }
        v.setOnClickPendingIntent(R.id.amrutham_root, openApp(context, widgetId, personId));
        v.setContentDescription(R.id.amrutham_root, "Emergency card for " + s.optString("name", ""));
    }
}
