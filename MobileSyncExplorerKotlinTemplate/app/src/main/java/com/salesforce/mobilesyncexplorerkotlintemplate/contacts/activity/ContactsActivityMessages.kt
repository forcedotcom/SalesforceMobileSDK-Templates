package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.activity

import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.*
import androidx.annotation.StringRes

enum class ContactsActivityMessages(@StringRes val stringRes: Int) {
    CleanGhostsFailed(message_clean_ghosts_failed),
    DeleteOperationFailed(message_delete_failed),
    RepoRefreshFailed(message_repo_refresh_failed),
    SyncDownFinishFailed(message_sync_down_finish_failed),
    SyncDownStartFailed(message_sync_down_start_failed),
    SyncUpFinishFailed(message_sync_up_finish_failed),
    SyncUpStartFailed(message_sync_up_start_failed),
    UndeleteOperationFailed(message_undelete_failed),
    UpdateOperationFailed(message_update_failed),
    WaitForDataOpToFinish(message_wait_for_data_op),
}
