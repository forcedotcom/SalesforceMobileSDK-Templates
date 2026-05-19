package com.example.minapp

import android.os.Bundle
import android.view.Gravity
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val label = TextView(this).apply {
            text = "Hello, minapp"
            gravity = Gravity.CENTER
            textSize = 18f
        }
        setContentView(label)
    }
}
