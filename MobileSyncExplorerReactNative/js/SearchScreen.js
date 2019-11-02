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

import React from 'react';
import {
    Alert,
    View,
    FlatList,
    Keyboard
} from 'react-native';
import { SearchBar } from 'react-native-elements';

import styles from './Styles';
import NavImgButton from './NavImgButton';
import ContactScreen from './ContactScreen';
import ContactCell from './ContactCell';
import storeMgr from './StoreMgr';

class SearchScreen extends React.Component {
    static navigationOptions = ({ navigation }) => {
        const { params = {} } = navigation.state;
        return {
            title: 'Contacts',
            headerRight: (
                    <View style={styles.navButtonsGroup}>
                    <NavImgButton icon='add' onPress={() => params.onAdd()} />
                    <NavImgButton icon='cloud-sync' iconType='material-community' onPress={() => params.onSync()} />
                    <NavImgButton icon='logout' iconType='material-community' onPress={() => params.onLogout()} />
                    </View>
            )
        };
    }

    constructor(props) {
        super(props);
        this.state = {
            isLoading: false,
            filter: '',
            data: [],
            queryNumber: 0
        };
        this.onSearchChange = this.onSearchChange.bind(this);
        this.onAdd = this.onAdd.bind(this);
        this.onSync = this.onSync.bind(this);
        this.onLogout = this.onLogout.bind(this);
        this.selectContact = this.selectContact.bind(this);
        this.extractKey = this.extractKey.bind(this);
        this.renderRow = this.renderRow.bind(this);
        this.refresh = this.refresh.bind(this);
    }

    componentDidMount() {
        this.props.navigation.setParams({
            onAdd: this.onAdd,
            onSync: this.onSync,
            onLogout: this.onLogout
        });
        storeMgr.syncData();
        storeMgr.addStoreChangeListener(this.refresh);
    }
    
    refresh() {
        this.searchContacts(this.state.filter);
    }

    render() {
        return (
                <View style={this.props.style}>
                  <SearchBar
                    lightTheme
                    autoCorrect={false}
                    onChangeText={this.onSearchChange}
                    showLoadingIcon={this.state.isLoading}
                    value={this.state.filter}    
                    placeholder='Search a contact...'
                  />
                  <FlatList
                    data={this.state.data}
                    keyExtractor={this.extractKey}
                    renderItem={this.renderRow} />
                </View>
      );
    }

    extractKey(item: Object) {
        return `list-${item._soupEntryId}`
    }

    renderRow(row: Object)  {
        const contact = row.item
        return (
                <ContactCell
                  onSelect={() => this.selectContact(contact)}
                  contact={contact}
                />
        );
    }

    selectContact(contact: Object) {
        Keyboard.dismiss()
        this.props.navigation.push('Contact', { contact:contact });
    }

    onSearchChange(text) {
        const filter = text.toLowerCase();
        clearTimeout(this.timeoutID);
        this.timeoutID = setTimeout(() => this.searchContacts(filter), 10);
    }

    onAdd() {
        const navigation = this.props.navigation;
        storeMgr.addContact(
            (contact) => navigation.push('Contact', {contact: contact})
        );
    }

    onSync() {
        storeMgr.reSyncData();
    }

    onLogout() {
        Alert.alert(
            'Logout',
            'Are you sure you want to logout',
            [
                {text: 'Cancel' },
                {text: 'OK', onPress: () => oauth.logout()},
            ],
            { cancelable: true }
        )
    }

    searchContacts(query: string) {
        this.setState({
            isLoading: true,
            filter: query
        });

        const that = this;
        storeMgr.searchContacts(
            query,
            (contacts, currentStoreQuery) => {
                that.setState({
                    isLoading: false,
                    filter: query,
                    data: contacts,
                    queryNumber: currentStoreQuery
                });
            },
            (error) => {
                that.setState({
                    isLoading: false
                });
            });
    }
}

export default SearchScreen;
