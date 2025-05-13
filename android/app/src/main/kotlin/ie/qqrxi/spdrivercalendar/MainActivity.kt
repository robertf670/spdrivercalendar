package ie.qqrxi.spdrivercalendar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.graphics.Rect
import android.view.ViewTreeObserver
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app.channel/text_rendering"
    private var initialLayoutComplete = false
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable hardware acceleration
        window.setFlags(
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        )
        
        // Add global layout listener
        // window.decorView.viewTreeObserver.addOnGlobalLayoutListener(object : ViewTreeObserver.OnGlobalLayoutListener {
        //     override fun onGlobalLayout() {
        //         if (!initialLayoutComplete) {
        //             initialLayoutComplete = true
        //             // Get the window visible display frame
        //             val rect = Rect()
        //             window.decorView.getWindowVisibleDisplayFrame(rect)
        //             
        //             // Set the window layout parameters
        //             val params = window.attributes
        //             params.width = rect.width()
        //             params.height = rect.height()
        //             window.attributes = params
        //             
        //             // Remove the listener
        //             window.decorView.viewTreeObserver.removeOnGlobalLayoutListener(this)
        //         }
        //     }
        // })
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Add the registrant call back BEFORE super
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Call super
        super.configureFlutterEngine(flutterEngine)
        
        // Set up method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "forceRebuild" -> {
                    // Force a layout pass
                    window.decorView.requestLayout()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        
        // Reset layout flag
        // initialLayoutComplete = false // Commenting this out as its primary use was with the removed GlobalLayoutListener
        
        // Force a new layout pass
        // window.decorView.requestLayout() // This might still be useful or could be removed if Flutter handles all redraws
        
        // Get the window visible display frame
        // val rect = Rect()
        // window.decorView.getWindowVisibleDisplayFrame(rect)
        
        // Update window layout parameters
        // val params = window.attributes
        // params.width = rect.width()
        // params.height = rect.height()
        // window.attributes = params
    }
}
