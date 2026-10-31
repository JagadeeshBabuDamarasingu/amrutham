package app.amrutham.widgets;

import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.view.View;
import android.widget.RemoteViews;

import org.json.JSONObject;

/** One big button that opens the dialer for the chosen contact. */
public class DialWidgetProvider extends CardProvider {
    @Override
    RemoteViews render(Context context, AppWidgetManager manager, int widgetId) {
        return build(context, manager, widgetId);
    }

    @Override
    int[] fields() {
        return new int[] {R.id.amrutham_name, R.id.amrutham_dial, R.id.amrutham_message};
    }

    @Override
    int layout(Context context, AppWidgetManager manager, int widgetId) {
        return R.layout.amrutham_dial_widget;
    }

    @Override
    void fill(Context context, RemoteViews v, int widgetId, String personId, JSONObject s) {
        JSONObject dial = s.optJSONObject("dial");
        if (dial == null) {
            // The person turned the button off, or has no contact with a number.
            v.setViewVisibility(R.id.amrutham_message, View.VISIBLE);
            v.setTextViewText(R.id.amrutham_message, "No number to dial for " + s.optString("name", "") + ". Add an emergency contact in Amrutham.");
            v.setOnClickPendingIntent(R.id.amrutham_root, openApp(context, widgetId, personId));
            return;
        }
        v.setViewVisibility(R.id.amrutham_dial, View.VISIBLE);
        v.setTextViewText(R.id.amrutham_dial, dial.optString("label", ""));
        v.setViewVisibility(R.id.amrutham_name, View.VISIBLE);
        v.setTextViewText(R.id.amrutham_name, "for " + s.optString("name", ""));
        v.setOnClickPendingIntent(R.id.amrutham_root, dial(context, widgetId, dial));
        v.setContentDescription(R.id.amrutham_root, "Dial " + dial.optString("label", "") + " for " + s.optString("name", ""));
    }
}
