import { LightningElement, api } from 'lwc';
import savePreferences from '@salesforce/apex/ParticipantHubController.savePreferences';
import { reduceError } from 'c/hubUtils';

const TEXT = {
    normal: {
        heading: 'My communication preferences',
        intro: 'Tell us how you like to be contacted. Your support team will see your changes.',
        contactLabel: 'Preferred way to contact me',
        choose: 'Choose one',
        needsLabel: 'Anything we should know when we talk to you?',
        easyReadLabel: 'Show my plan in Easy Read by default',
        supportNameLabel: 'Support person name',
        supportPhoneLabel: 'Support person phone',
        save: 'Save my preferences',
        saving: 'Saving…',
        saved: 'Saved. Your support team can now see your changes.'
    },
    easy: {
        heading: 'How to talk to me',
        intro: 'Tell us how you like us to talk to you.',
        contactLabel: 'How should we contact me?',
        choose: 'Pick one',
        needsLabel: 'What helps when we talk to you?',
        easyReadLabel: 'Always show my plan in Easy Read',
        supportNameLabel: 'Name of my support person',
        supportPhoneLabel: 'Phone number of my support person',
        save: 'Save',
        saving: 'Saving…',
        saved: 'Saved. Thank you.'
    }
};

export default class HubPreferencesEditor extends LightningElement {
    @api easyRead = false;

    _plan;
    dirty = false;
    contactMethod = '';
    needs = '';
    easyReadPref = false;
    supportName = '';
    supportPhone = '';
    isSaving = false;
    message = '';
    messageIsError = false;

    @api
    get plan() {
        return this._plan;
    }
    set plan(value) {
        this._plan = value;
        // Do not overwrite what the person is typing if the plan refreshes underneath them.
        if (value && !this.dirty) {
            this.loadFromPlan(value);
        }
    }

    get t() {
        return this.easyRead ? TEXT.easy : TEXT.normal;
    }

    get saveLabel() {
        return this.isSaving ? this.t.saving : this.t.save;
    }

    get messageText() {
        if (!this.message) {
            return '';
        }
        return this.messageIsError ? `Problem: ${this.message}` : this.message;
    }

    get contactOptions() {
        const values = this._plan?.contactMethodOptions || [];
        return [
            { value: '', label: this.t.choose, selected: !this.contactMethod },
            ...values.map((value) => ({ value, label: value, selected: value === this.contactMethod }))
        ];
    }

    loadFromPlan(plan) {
        this.contactMethod = plan.preferredContactMethod || '';
        this.needs = plan.communicationNeeds || '';
        this.easyReadPref = !!plan.easyReadPreferred;
        this.supportName = plan.supportPersonName || '';
        this.supportPhone = plan.supportPersonPhone || '';
    }

    handleChange(event) {
        const { name, value, checked } = event.target;
        switch (name) {
            case 'contactMethod':
                this.contactMethod = value;
                break;
            case 'needs':
                this.needs = value;
                break;
            case 'easyReadPref':
                this.easyReadPref = checked;
                break;
            case 'supportName':
                this.supportName = value;
                break;
            case 'supportPhone':
                this.supportPhone = value;
                break;
            default:
                break;
        }
        this.dirty = true;
        this.message = '';
    }

    async handleSave(event) {
        event.preventDefault();
        if (!this._plan || this.isSaving) {
            return;
        }
        this.isSaving = true;
        this.message = '';
        try {
            await savePreferences({
                planId: this._plan.planId,
                preferredContactMethod: this.contactMethod || null,
                communicationNeeds: this.needs,
                easyReadPreferred: this.easyReadPref,
                supportPersonName: this.supportName,
                supportPersonPhone: this.supportPhone
            });
            this.dirty = false;
            this.messageIsError = false;
            this.message = this.t.saved;
            this.dispatchEvent(new CustomEvent('planchange'));
        } catch (error) {
            this.messageIsError = true;
            this.message = reduceError(error);
        } finally {
            this.isSaving = false;
        }
    }
}
