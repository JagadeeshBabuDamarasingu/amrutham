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
    private static final String CHANNEL = "amrutham_lock_notice";

    private LockNotice() {}

    static void show(Context context, int id, String title, String body, List<Map<String, String>> dials) {
        NotificationManager manager = context.getSystemService(NotificationManager.class);
        if (manager == null) return;
        NotificationChannel channel = new NotificationChannel(
                CHANNEL, "Emergency details on lock screen", NotificationManager.IMPORTANCE_LOW);
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
        NotificationManager manager = context.getSystemService(NotificationManager.class);
        if (manager != null) manager.cancel(id);
    }
}
