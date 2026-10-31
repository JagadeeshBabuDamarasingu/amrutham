package app.amrutham.widgets;

import android.app.Activity;
import android.app.AlertDialog;
import android.appwidget.AppWidgetManager;
import android.content.Intent;
import android.os.Bundle;

import org.json.JSONArray;
import org.json.JSONObject;

/**
 * The screen the phone shows when a card is added: who is it for? It lists
 * names only, from the copy the app keeps while the cards are switched on.
 */
public class CardConfigActivity extends Activity {
    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        setResult(RESULT_CANCELED);
        final int widgetId = getIntent().getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID);
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish();
            return;
        }
        if (!WidgetStore.enabled(this)) {
            new AlertDialog.Builder(this)
                    .setTitle("Emergency cards are off")
                    .setMessage("Open Amrutham, then Settings, then Home screen widgets, and turn them on. Then add the card again.")
                    .setPositiveButton("OK", (d, w) -> finish())
                    .setOnCancelListener(d -> finish())
                    .show();
            return;
        }
        String pending = WidgetStore.takePending(this);
        if (pending != null) {
            choose(widgetId, pending);
            return;
        }
        final JSONArray people = WidgetStore.people(this);
        if (people.length() == 0) {
            new AlertDialog.Builder(this)
                    .setTitle("Nobody to show yet")
                    .setMessage("Add a family member in Amrutham first.")
                    .setPositiveButton("OK", (d, w) -> finish())
                    .setOnCancelListener(d -> finish())
                    .show();
            return;
        }
        String[] names = new String[people.length()];
        for (int i = 0; i < names.length; i++) names[i] = people.optJSONObject(i).optString("name", "");
        new AlertDialog.Builder(this)
                .setTitle("Who is this card for?")
                .setItems(names, (d, which) -> {
                    JSONObject p = people.optJSONObject(which);
                    choose(widgetId, p.optString("id", ""));
                })
                .setOnCancelListener(d -> finish())
                .show();
    }

    /** Draws the widget with the provider it was placed from. */
    private android.widget.RemoteViews renderFor(int widgetId) {
        AppWidgetManager manager = AppWidgetManager.getInstance(this);
        android.appwidget.AppWidgetProviderInfo info = manager.getAppWidgetInfo(widgetId);
        try {
            CardProvider p = info != null && info.provider != null
                    ? (CardProvider) Class.forName(info.provider.getClassName()).getDeclaredConstructor().newInstance()
                    : new EmergencyWidgetProvider();
            return p.render(this, manager, widgetId);
        } catch (Exception e) {
            return new EmergencyWidgetProvider().render(this, manager, widgetId);
        }
    }

    private void choose(int widgetId, String personId) {
        WidgetStore.setPerson(this, widgetId, personId);
        AppWidgetManager.getInstance(this).updateAppWidget(widgetId, renderFor(widgetId));
        Intent result = new Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId);
        setResult(RESULT_OK, result);
        finish();
    }
}
