package app.amrutham.widgets;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.drawable.Icon;
import android.net.Uri;
import android.os.Build;

import java.util.List;
import java.util.Map;

/**
 * The emergency details as a pinned notification on the lock screen, with a
 * button per number to dial. The buttons open the dialer with the number
 * filled in (the person still presses call), so no phone permission is needed.
 */
final class LockNotice {
    // A new id each time the channel's settings change: Android keeps a channel's
    // sound and importance from when it was first created.
    private static final String CHANNEL = "amrutham_lock_notice_v2";
    static final String PREFS = "amrutham_lock_notice";

    private LockNotice() {}

    static void show(Context context, int id, String title, String body, List<Map<String, String>> dials) {
        try {
            org.json.JSONArray list = new org.json.JSONArray();
            for (Map<String, String> d : dials) list.put(new org.json.JSONObject(d));
            org.json.JSONObject saved = new org.json.JSONObject();
            saved.put("title", title).put("body", body).put("dials", list);
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString("n" + id, saved.toString()).apply();
        } catch (org.json.JSONException ignored) {
            // Not saved: it just can't come back after being swiped away.
        }
        post(context, id, title, body, dials);
    }

    /** Posts it again after it was swiped away (Android 14 allows that for pinned ones). */
    static void repost(Context context, int id) {
        String raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("n" + id, null);
        if (raw == null) return;
        try {
            org.json.JSONObject saved = new org.json.JSONObject(raw);
            List<Map<String, String>> dials = new java.util.ArrayList<>();
            org.json.JSONArray list = saved.getJSONArray("dials");
            for (int i = 0; i < list.length(); i++) {
                Map<String, String> d = new java.util.HashMap<>();
                d.put("label", list.getJSONObject(i).getString("label"));
                d.put("number", list.getJSONObject(i).getString("number"));
                dials.add(d);
            }
            post(context, id, saved.getString("title"), saved.getString("body"), dials);
        } catch (org.json.JSONException ignored) {
            // Damaged copy: leave it gone.
        }
    }

    private static void post(Context context, int id, String title, String body, List<Map<String, String>> dials) {
        NotificationManager manager = context.getSystemService(NotificationManager.class);
        if (manager == null) return;
        // Default importance, not low: low ones go under "Silent" and many phones
        // hide those on the lock screen. No sound or buzz, so it is still quiet.
        NotificationChannel channel = new NotificationChannel(
                CHANNEL, "Emergency details on lock screen", NotificationManager.IMPORTANCE_DEFAULT);
        channel.setSound(null, null);
        channel.enableVibration(false);
        channel.enableLights(false);
        channel.setDescription("Shows emergency details on the lock screen, for the people you chose");
        channel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
        channel.setShowBadge(false);
        manager.createNotificationChannel(channel);

        Icon icon = Icon.createWithResource(context, context.getApplicationInfo().icon);
        Notification.Builder builder = new Notification.Builder(context, CHANNEL)
                .setSmallIcon(icon)
                .setContentTitle(title)
                .setContentText(body.split("\n")[0])
                .setStyle(new Notification.BigTextStyle().bigText(body))
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setCategory(Notification.CATEGORY_STATUS)
                .setOngoing(true)
                .setAutoCancel(false)
                .setShowWhen(false)
                .setOnlyAlertOnce(true);

        builder.setDeleteIntent(PendingIntent.getBroadcast(
                context, id, new Intent(context, LockNoticeReceiver.class).putExtra("id", id),
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT));
        Intent open = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
        if (open != null) {
            builder.setContentIntent(PendingIntent.getActivity(
                    context, id, open, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT));
        }
        int n = 0;
        for (Map<String, String> d : dials) {
            String number = d.get("number");
            if (number == null || n == 3) continue; // Android shows at most three buttons
            Intent dial = new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + Uri.encode(number)));
            PendingIntent pending = PendingIntent.getActivity(
                    context, id + 1 + n, dial, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
            builder.addAction(new Notification.Action.Builder(null, d.get("label"), pending).build());
            n++;
        }
        manager.notify(id, builder.build());
    }

    static void hide(Context context, int id) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove("n" + id).apply();
        NotificationManager manager = context.getSystemService(NotificationManager.class);
        if (manager != null) manager.cancel(id);
    }
}
