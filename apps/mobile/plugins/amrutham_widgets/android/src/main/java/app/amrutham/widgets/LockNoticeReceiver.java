package app.amrutham.widgets;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Puts the lock screen notice back when it is swiped away; turning it off in the app removes the saved copy. */
public class LockNoticeReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        LockNotice.repost(context, intent.getIntExtra("id", 0));
    }
}
