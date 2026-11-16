import { LightningElement, api } from 'lwc';
import createChangeRequest from '@salesforce/apex/ParticipantHubController.createChangeRequest';
import { formatDate, reduceError } from 'c/hubUtils';

const TEXT = {
    normal: {
        heading: 'Ask for a change to my plan',
        intro: 'Send a request and your support team will review it.',
        typeLabel: 'What would you like to change?',
        choose: 'Choose one',
        detailsLabel: 'Tell us about the change',
        submit: 'Send request',
        sending: 'Sending…',
        sent: 'Request sent. Your support team will get back to you.',
        needType: 'Please choose what you would like to change.',
        needDetails: 'Please tell us about the change you would like.',
        historyHeading: 'My requests',
        noRequests: 'You have not sent any requests yet.',
        response: 'Reply from support team:'
    },
    easy: {
        heading: 'I want to change my plan',
        intro: 'Tell us what you want to change. We will read it.',
        typeLabel: 'What do you want to change?',
        choose: 'Pick one',
        detailsLabel: 'Tell us more',
        submit: 'Send',
        sending: 'Sending…',
        sent: 'Sent. We will get back to you.',
        needType: 'Please pick what you want to change.',
        needDetails: 'Please tell us more.',
        historyHeading: 'My requests',
        noRequests: 'No requests yet.',
        response: 'Our reply:'
    }
};

const STATUS_EASY = {
    Submitted: 'We got it',
    Approved: 'Yes',
    Declined: 'Not this time'
};

export default class HubChangeRequests extends LightningElement {
    @api plan;
    @api easyRead = false;

    requestType = '';
    details = '';
    isSaving = false;
    message = '';
    messageIsError = false;

    get t() {
        return this.easyRead ? TEXT.easy : TEXT.normal;
    }

    get submitLabel() {
        return this.isSaving ? this.t.sending : this.t.submit;
    }

    get messageText() {
        if (!this.message) {
            return '';
        }
        return this.messageIsError ? `Problem: ${this.message}` : this.message;
    }

    get typeOptions() {
        const values = this.plan?.requestTypeOptions || [];
        return [
            { value: '', label: this.t.choose, selected: !this.requestType },
            ...values.map((value) => ({ value, label: value, selected: value === this.requestType }))
        ];
    }

    get noRequests() {
        return !this.plan?.requests || this.plan.requests.length === 0;
    }

    get requests() {
        return (this.plan?.requests || []).map((request) => ({
            key: request.recordId,
            requestType: request.requestType || 'Request',
            details: request.details,
            staffResponse: request.staffResponse,
            hasResponse: !!request.staffResponse,
            statusLabel: this.easyRead ? STATUS_EASY[request.status] || request.status : request.status,
            dateText: formatDate(request.createdDate)
        }));
    }

    handleChange(event) {
        const { name, value } = event.target;
        if (name === 'requestType') {
            this.requestType = value;
        } else if (name === 'details') {
            this.details = value;
        }
        this.message = '';
    }

    async handleSubmit(event) {
        event.preventDefault();
        if (this.isSaving) {
            return;
        }
        if (!this.requestType) {
            this.showError(this.t.needType);
            return;
        }
        if (!this.details || !this.details.trim()) {
            this.showError(this.t.needDetails);
            return;
        }

        this.isSaving = true;
        this.message = '';
        try {
            await createChangeRequest({
                planId: this.plan.planId,
                requestType: this.requestType,
                details: this.details
            });
            this.requestType = '';
            this.details = '';
            this.messageIsError = false;
            this.message = this.t.sent;
            this.dispatchEvent(new CustomEvent('planchange'));
        } catch (error) {
            this.showError(reduceError(error));
        } finally {
            this.isSaving = false;
        }
    }

    showError(text) {
        this.messageIsError = true;
        this.message = text;
    }
}
