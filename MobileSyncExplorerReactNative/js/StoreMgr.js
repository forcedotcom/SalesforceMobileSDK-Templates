/*
 * Copyright (c) 2015-present, salesforce.com, inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided
 * that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the
 * following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
 * the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or
 * promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

import EventEmitter from './events';
import {smartstore, mobilesync, forceUtil} from 'react-native-force';

const registerSoup = forceUtil.promiser(smartstore.registerSoup);
const getSyncStatus = forceUtil.promiser(mobilesync.getSyncStatus);
const syncDown = forceUtil.promiserNoRejection(mobilesync.syncDown);
const syncUp = forceUtil.promiserNoRejection(mobilesync.syncUp);
const reSync = forceUtil.promiserNoRejection(mobilesync.reSync);

const syncName = "mobileSyncExplorerSyncDown";
let syncInFlight = false;
let lastStoreQuerySent = 0;
let lastStoreResponseReceived = 0;
const eventEmitter = new EventEmitter();

const SMARTSTORE_CHANGED = "smartstoreChanged";

function emitSmartStoreChanged() {
    eventEmitter.emit(SMARTSTORE_CHANGED, {});
}

function syncDownContacts() {
    if (syncInFlight) {
        console.log("Not starting syncDown - sync already in fligtht");
        return Promise.resolve();
    }
    
    console.log("Starting syncDown");
    syncInFlight = true;
    const fieldlist = ["Id", "FirstName", "LastName", "Title", "Email", "MobilePhone","Department", "LastModifiedDate"];
    const target = {type:"soql", query:`SELECT ${fieldlist.join(",")} FROM Contact LIMIT 10000`};
    return syncDown(false, target, "contacts", {mergeMode:mobilesync.MERGE_MODE.OVERWRITE}, syncName)
        .then(() => {
            console.log("syncDown completed or failed");
            syncInFlight = false;
            emitSmartStoreChanged();
        });
}

function reSyncContacts() {
    if (syncInFlight) {
        console.log("Not starting reSync - sync already in fligtht");
        return Promise.resolve();
    }

    console.log("Starting reSync");
    syncInFlight = true;
    return reSync(false, syncName)
        .then(() => {
            console.log("reSync completed or failed");
            syncInFlight = false;
            emitSmartStoreChanged();
        });
}

function syncUpContacts() {
    if (syncInFlight) {
        console.log("Not starting syncUp - sync already in fligtht");
        return Promise.resolve();
    }

    console.log("Starting syncUp");
    syncInFlight = true;
    const fieldlist = ["FirstName", "LastName", "Title", "Email", "MobilePhone","Department"];
    return syncUp(false, {}, "contacts", {mergeMode:mobilesync.MERGE_MODE.OVERWRITE, fieldlist})
        .then(() => {
            console.log("syncUp completed or failed");
            syncInFlight = false;
            emitSmartStoreChanged();
        });
}

function firstTimeSyncData() {
    return registerSoup(false,
                        "contacts", 
                        [ {path:"Id", type:"string"}, 
                          {path:"FirstName", type:"full_text"}, 
                          {path:"LastName", type:"full_text"}, 
                          {path:"__local__", type:"string"} ])
        .then(syncDownContacts);
}

function syncData() {
    return getSyncStatus(false, syncName)
        .then((sync) => {
            if (sync == null) {
                return firstTimeSyncData();
            } else {
                return reSyncData();
            }
        });
}

function reSyncData() {
    return syncUpContacts()
        .then(reSyncContacts);
}

function addStoreChangeListener(listener) {
    eventEmitter.addListener(SMARTSTORE_CHANGED, listener);
}

function saveContact(contact, callback) {
    smartstore.upsertSoupEntries(false, "contacts", [contact],
                                 () => {
                                     callback();
                                     emitSmartStoreChanged();
                                 });
}

function addContact(successCallback, errorCallback) {
    const contact = {Id: `local_${(new Date()).getTime()}`,
                   FirstName: null, LastName: null, Title: null, Email: null, MobilePhone: null, Department: null, attributes: {type: "Contact"},
                   __locally_created__: true,
                   __locally_updated__: false,
                   __locally_deleted__: false,
                   __local__: true
                  };
    smartstore.upsertSoupEntries(false, "contacts", [ contact ],
                                 (contacts) => successCallback(contacts[0]),
                                 errorCallback);
}

function deleteContact(contact, successCallback, errorCallback) {
    smartstore.removeFromSoup(false, "contacts", [ contact._soupEntryId ],
                              successCallback,
                              errorCallback);
}

function traverseCursor(accumulatedResults, cursor, pageIndex, successCallback, errorCallback) {
    accumulatedResults = accumulatedResults.concat(cursor.currentPageOrderedEntries);
    if (pageIndex < cursor.totalPages - 1) {
        smartstore.moveCursorToPageIndex(false, cursor, pageIndex + 1,
                                         (cursor) => {
                                             traverseCursor(accumulatedResults, cursor, pageIndex + 1, successCallback, errorCallback);
                                         },
                                         errorCallback);
    }
    else {
        successCallback(accumulatedResults);
    }
}

function searchContacts(queryId, query, successCallback, errorCallback) {
    let querySpec;
    
    if (query === "") {
        querySpec = smartstore.buildAllQuerySpec("LastName", "ascending", 100);
    }
    else {
        const queryParts = query.split(/ /);
        const queryFirst = queryParts.length == 2 ? queryParts[0] : query;
        const queryLast = queryParts.length == 2 ? queryParts[1] : query;
        const queryOp = queryParts.length == 2 ? "AND" : "OR";
        const match = `{contacts:FirstName}:${queryFirst}* ${queryOp} {contacts:LastName}:${queryLast}*`;
        querySpec = smartstore.buildMatchQuerySpec(null, match, "ascending", 100, "LastName");
    }
    const that = this;

    const querySuccessCB = (contacts) => {
        successCallback(contacts, queryId);
    };

    const queryErrorCB = (error) => {
        console.log(`Error->${JSON.stringify(error)}`);
        errorCallback(error);
    };

    smartstore.querySoup(false,
                         "contacts",
                         querySpec,
                         (cursor) => {
                             traverseCursor([], cursor, 0, querySuccessCB, queryErrorCB);
                         },
                         queryErrorCB);

}


export default {
    syncData,
    reSyncData,
    addStoreChangeListener,
    saveContact,
    searchContacts,
    addContact,
    deleteContact,
};
