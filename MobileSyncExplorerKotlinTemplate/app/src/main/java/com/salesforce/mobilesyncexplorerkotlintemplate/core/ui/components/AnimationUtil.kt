package com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components

import androidx.compose.animation.core.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State

@Composable
fun rememberSimpleSpinAnimation(hertz: Float): State<Float> {
    val transition = rememberInfiniteTransition()
    return transition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            tween(
                durationMillis = (1000 / hertz).toInt(),
                easing = LinearEasing
            )
        )
    )
}
