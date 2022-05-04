package com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions

private val newlineCharRegex by lazy { Regex("\\R") }

fun String.removeNewlineChars(): String = replace(newlineCharRegex, "")
fun String.removeTabChars(): String = replace("\t", "")
