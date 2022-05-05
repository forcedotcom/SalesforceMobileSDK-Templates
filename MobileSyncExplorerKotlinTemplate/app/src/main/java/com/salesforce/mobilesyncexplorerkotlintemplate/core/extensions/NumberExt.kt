package com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions

fun UInt.coerceToNonNegativeInt(): Int = coerceIn(0u..Int.MAX_VALUE.toUInt()).toInt()
