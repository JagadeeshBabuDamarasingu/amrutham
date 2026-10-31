package app.amrutham.widgets;

import android.content.Context;
import android.content.SharedPreferences;

import org.json.JSONArray;

import java.util.Map;

/**
 * The widgets' own copy of what they may show. It lives in app-private
 * preferences and is excluded from Android's cloud backup and device transfer
 * (see the backup rules in the app). The app writes only the fields the person
 * turned on, and wipes everything when the cards are switched off.
 */
final class WidgetStore {
    static final String FILE = "amrutham_widgets";
    private static final String ENABLED = "enabled";
    private static final String PEOPLE = "people";
    private static final String SNAP = "snap_";
    private static final String WIDGET = "widget_";
    private static final String PENDING = "pending_person";
    private static final String PENDING_AT = "pending_at";
    private static final long PENDING_MS = 2 * 60 * 1000;

    private WidgetStore() {}

    private static SharedPreferences prefs(Context c) {
        return c.getApplicationContext().getSharedPreferences(FILE, Context.MODE_PRIVATE);
    }

    static boolean enabled(Context c) {
        return prefs(c).getBoolean(ENABLED, false);
    }

    static JSONArray people(Context c) {
        try {
            return new JSONArray(prefs(c).getString(PEOPLE, "[]"));
        } catch (Exception e) {
            return new JSONArray();
        }
    }

    static String snapshot(Context c, String personId) {
        return prefs(c).getString(SNAP + personId, null);
    }

    static String personFor(Context c, int widgetId) {
        return prefs(c).getString(WIDGET + widgetId, null);
    }

    static void setPerson(Context c, int widgetId, String personId) {
        prefs(c).edit().putString(WIDGET + widgetId, personId).apply();
    }

    static void forget(Context c, int widgetId) {
        prefs(c).edit().remove(WIDGET + widgetId).apply();
    }

    /** Replaces the whole copy. Nothing from an earlier sync survives. */
    static void replace(Context c, boolean enabled, String peopleJson, Map<String, String> snapshots) {
        SharedPreferences p = prefs(c);
        SharedPreferences.Editor e = p.edit();
        for (String key : p.getAll().keySet()) {
            if (key.startsWith(SNAP)) e.remove(key);
        }
        e.putBoolean(ENABLED, enabled);
        if (enabled) {
            e.putString(PEOPLE, peopleJson);
            for (Map.Entry<String, String> s : snapshots.entrySet()) {
                e.putString(SNAP + s.getKey(), s.getValue());
            }
        } else {
            e.remove(PEOPLE).remove(PENDING).remove(PENDING_AT);
        }
        e.apply();
    }

    /** The person a card being added from the app is for, for a short while. */
    static void setPending(Context c, String personId) {
        prefs(c).edit().putString(PENDING, personId).putLong(PENDING_AT, System.currentTimeMillis()).apply();
    }

    /** Returns the pending person once, or null if none or it has gone stale. */
    static String takePending(Context c) {
        SharedPreferences p = prefs(c);
        String id = p.getString(PENDING, null);
        long at = p.getLong(PENDING_AT, 0);
        p.edit().remove(PENDING).remove(PENDING_AT).apply();
        return id != null && System.currentTimeMillis() - at <= PENDING_MS ? id : null;
    }
}
