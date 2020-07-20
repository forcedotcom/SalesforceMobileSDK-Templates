import { LightningElement, track, api } from 'lwc';
export default class ContactList extends LightningElement {
    @api mobilesdk;
	@track contacts;
	@track error;
	connectedCallback() {
        this.loadContacts();
	}
	loadContacts() {
        let soql = 'SELECT Id, Name, MobilePhone, Department FROM Contact LIMIT 100';
        this.mobilesdk.force.query(soql, 
            (result) => {
                this.contacts = result.records;
            },
            (error) => {
                this.error = error;
            }
        );
    }

    handleSelect(event) {
        // 1. Prevent default behavior of anchor tag click which is to navigate to the href url
        event.preventDefault();
        // 2. Create a custom event that bubbles. Read about event best practices at http://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.events_best_practices
        const selectEvent = new CustomEvent('contactselect', {
            detail: { contactId: event.currentTarget.dataset.contactId }
        });
        // 3. Fire the custom event
        this.dispatchEvent(selectEvent);
    }
}