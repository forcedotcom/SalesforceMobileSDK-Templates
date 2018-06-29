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
    Image,
    PixelRatio,
    StyleSheet,
    Text,
    TouchableHighlight,
    View
} from 'react-native';

const colors = ["#1abc9c", "#2ecc71", "#3498db", "#9b59b6", "#34495e", "#16a085", "#27ae60", "#2980b9", "#8e44ad", "#2c3e50", "#f1c40f", "#e67e22", "#e74c3c", "#95a5a6", "#f39c12", "#d35400", "#c0392b", "#bdc3c7", "#7f8c8d"];

class ContactBadge extends React.Component {
    render() {
        // Compute initials
        const firstName = this.props.contact.FirstName;
        const lastName = this.props.contact.LastName;
        const initials = (firstName ? firstName.substring(0,1) : "") + (lastName ? lastName.substring(0,1) : "");
        // Compute color
        let code = 0;
        if (lastName) {
            for (let i=0; i< lastName.length; i++) {
                code += lastName.charCodeAt(i);
            }
        }
        const color = colors[code % colors.length];
        return (
                <View style={[styles.circle, {backgroundColor: color}]}>
                  <Text style={styles.initials}>{initials}</Text>
                </View>           
               );
    }
}

var styles = StyleSheet.create({
    circle: {
        justifyContent: 'center',
        alignItems: 'center',
        width:50,
        height:50,
        borderRadius: 25,
        backgroundColor:'#1abc9c',
        marginRight:5
    },
    initials: {
        fontSize:19,
        color:'white',
        backgroundColor:'transparent',
        fontFamily: 'Helvetica Neue'
    }
});

export default ContactBadge;
