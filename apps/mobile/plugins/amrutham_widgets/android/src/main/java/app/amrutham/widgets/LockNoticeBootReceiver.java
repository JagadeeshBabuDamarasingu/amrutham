package app.amrutham.widgets;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import java.util.Map;

/** Android clears notifications when the phone restarts: put the lock screen notices back. */
public class LockNoticeBootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (!Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) return;
        Map<String, ?> saved = context.getSharedPreferences(LockNotice.PREFS, Context.MODE_PRIVATE).getAll();
        for (String key : saved.keySet()) {
            if (!key.startsWith("n")) continue;
            try {
                LockNotice.repost(context, Integer.parseInt(key.substring(1)));
            } catch (NumberFormatException ignored) {
                // Not one of ours.
            }
        }
    }
}
