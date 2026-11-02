package com.bluebubbles.messaging.services.facetime

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.annotation.RequiresApi
import com.bluebubbles.messaging.R

class FaceTimeInCallService: Service() {

    @RequiresApi(Build.VERSION_CODES.O)
    fun createNotificationChannel() {
        val importance = NotificationManager.IMPORTANCE_LOW
        val channel = NotificationChannel(IN_CALL_CHANNEL, "In Call", importance).apply {
            description = "Shows the state of an in-progress FaceTime call"
        }
        // Register the channel with the system
        val notificationManager: NotificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    val IN_CALL_CHANNEL = "com.bluebubbles.in_call_channel";
    @RequiresApi(Build.VERSION_CODES.O)
    fun notifyForeground(serviceIntent: Intent?) {
        createNotificationChannel()

        val launchIntent = Intent(this, FaceTimeActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
        serviceIntent?.getBundleExtra("launch_extras")?.let { launchIntent.putExtras(it) }
        val contentIntent = PendingIntent.getActivity(
            this,
            90210,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification: Notification = Notification.Builder(this, IN_CALL_CHANNEL)
            .setContentTitle("FaceTime call in progress")
            .setContentText("Tap to return to the call")
            .setContentIntent(contentIntent)
            .setSmallIcon(R.mipmap.ic_stat_icon)
            .setCategory(Notification.CATEGORY_CALL)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setShowWhen(true)
            .build()

        var type: Int = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (checkSelfPermission(android.Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                type = type or ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA
            }
            if (checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
                type = type or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            }
        }

        try {
            // Notification ID cannot be 0. The foreground-service-type overload
            // only exists on Android 10+, so keep the two-arg call for older
            // releases.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(3884786, notification, type)
            } else {
                startForeground(3884786, notification)
            }
        } catch (e: Exception) {
            Log.e("FaceTime", "Unable to enter the foreground call state", e)
            // Stop before the system's five-second startForeground deadline.
            stopSelf()
        }
    }

    override fun onCreate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
        }
        super.onCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notifyForeground(intent)
        }
        // Never restart an empty call service after the process is killed.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }


    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}