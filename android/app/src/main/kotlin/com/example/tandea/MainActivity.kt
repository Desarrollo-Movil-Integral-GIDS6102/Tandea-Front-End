package com.example.tandea

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        crearCanalDeAvisos()
    }

    /**
     * Canal de importancia alta para los push de FCM. Con la importancia por defecto
     * (el canal de respaldo de Firebase) Android deja el aviso en la barra sin banner.
     * El id debe coincidir con default_notification_channel_id del AndroidManifest.
     */
    private fun crearCanalDeAvisos() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val canal = NotificationChannel(
            "tandea_avisos",
            "Avisos de Tandea",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply { description = "Pagos, entregas y recordatorios de tus tandas" }
        getSystemService(NotificationManager::class.java).createNotificationChannel(canal)
    }
}
