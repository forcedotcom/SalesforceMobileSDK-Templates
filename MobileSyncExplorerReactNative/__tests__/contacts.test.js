/*
 * Copyright (c) 2026-present, salesforce.com, inc.
 * All rights reserved.
 */

import React from 'react';
import {Text, TextInput, TouchableOpacity} from 'react-native';
import {act, create} from 'react-test-renderer';
import ContactCell from '../js/ContactCell';
import ContactScreen from '../js/ContactScreen';
import SearchScreen from '../js/SearchScreen';
import storeMgr from '../js/StoreMgr';

jest.mock('../js/StoreMgr', () => ({
    addStoreChangeListener: jest.fn(),
    syncData: jest.fn(() => Promise.resolve()),
    searchContacts: jest.fn((sequence, _query, success) => success([], sequence)),
    saveContact: jest.fn((_contact, success) => success()),
}));
jest.mock('react-native-force', () => ({oauth: {}}));
jest.mock('react-native-vector-icons/MaterialIcons', () => 'MaterialIcon');
jest.mock('react-native-vector-icons/MaterialCommunityIcons', () => 'CommunityIcon');

describe('Contact controls without a UI dependency', () => {
    let app;

    beforeEach(() => {
        jest.useFakeTimers();
        jest.clearAllMocks();
    });

    afterEach(() => {
        act(() => app?.unmount());
        jest.clearAllTimers();
        jest.useRealTimers();
    });

    it('selects a contact and preserves the sync error indicator', () => {
        const onSelect = jest.fn();
        act(() => {
            app = create(<ContactCell onSelect={onSelect} contact={{
                FirstName: 'Sample', LastName: 'Contact', Title: 'Engineer',
                __local__: true, __last_error__: 'Sync failed',
            }} />);
        });
        expect(app.root.findAllByType(Text).map(text => text.props.children))
            .toContain('Sample Contact');
        expect(app.root.findByType('MaterialIcon').props.name).toBe('sync-problem');
        act(() => app.root.findByType(TouchableOpacity).props.onPress());
        expect(onSelect).toHaveBeenCalledTimes(1);
    });

    it('edits and saves contact fields through the existing store', () => {
        const pop = jest.fn();
        act(() => {
            app = create(<ContactScreen route={{params: {contact: {
                FirstName: 'Sample', LastName: 'Contact',
            }}}} navigation={{setOptions: jest.fn(), pop}} />);
        });
        const field = app.root.findAllByType(TextInput).find(input =>
            input.props.accessibilityLabel === 'First name');
        act(() => field.props.onChangeText('Updated'));
        const save = app.root.findAllByType(TouchableOpacity).find(button =>
            button.props.accessibilityLabel === 'Save contact');
        act(() => save.props.onPress());
        expect(storeMgr.saveContact).toHaveBeenCalledWith(expect.objectContaining({
            FirstName: 'Updated', __local__: true, __locally_updated__: true,
        }), expect.any(Function));
        expect(pop).toHaveBeenCalledTimes(1);
    });

    it('searches and clears contacts through the existing query handler', () => {
        act(() => {
            app = create(<SearchScreen navigation={{setOptions: jest.fn()}} />);
        });
        act(() => app.root.findByType(TextInput).props.onChangeText('Sample'));
        act(() => jest.runOnlyPendingTimers());
        expect(storeMgr.searchContacts).toHaveBeenLastCalledWith(
            expect.any(Number), 'sample', expect.any(Function), expect.any(Function));
        const clear = app.root.findAllByType(TouchableOpacity).find(button =>
            button.props.accessibilityLabel === 'Clear search');
        act(() => clear.props.onPress());
        act(() => jest.runOnlyPendingTimers());
        expect(storeMgr.searchContacts).toHaveBeenLastCalledWith(
            expect.any(Number), '', expect.any(Function), expect.any(Function));
        expect(app.root.findByType(TextInput).props.value).toBe('');
    });
});
