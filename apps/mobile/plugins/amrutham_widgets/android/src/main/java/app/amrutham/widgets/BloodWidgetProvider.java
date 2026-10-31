package app.amrutham.widgets;

import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.view.View;
import android.widget.RemoteViews;

import org.json.JSONObject;

/** Blood group and allergies, and nothing else, for a glance. */
public class BloodWidgetProvider extends CardProvider {
    @Override
    RemoteViews render(Context context, AppWidgetManager manager, int widgetId) {
        return build(context, manager, widgetId);
    }

    @Override
    int[] fields() {
        return new int[] {
            R.id.amrutham_name, R.id.amrutham_blood_tile, R.id.amrutham_blood_note,
            R.id.amrutham_allergies, R.id.amrutham_message,
        };
    }

    @Override
    int layout(Context context, AppWidgetManager manager, int widgetId) {
        return R.layout.amrutham_blood_widget;
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
        v.setOnClickPendingIntent(R.id.amrutham_root, openApp(context, widgetId, personId));
        v.setContentDescription(R.id.amrutham_root, "Blood group and allergies for " + s.optString("name", ""));
    }
}
