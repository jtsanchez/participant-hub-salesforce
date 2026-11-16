import { LightningElement, api } from 'lwc';

export default class HubAccessibilityToolbar extends LightningElement {
    @api textSizeLabel = '100%';
    @api highContrast = false;
    @api easyRead = false;

    get contrastPressed() {
        return this.highContrast ? 'true' : 'false';
    }

    get easyReadPressed() {
        return this.easyRead ? 'true' : 'false';
    }

    get contrastState() {
        return this.highContrast ? 'On' : 'Off';
    }

    get easyReadState() {
        return this.easyRead ? 'On' : 'Off';
    }

    handleSmaller() {
        this.dispatchEvent(new CustomEvent('textsizechange', { detail: 'decrease' }));
    }

    handleLarger() {
        this.dispatchEvent(new CustomEvent('textsizechange', { detail: 'increase' }));
    }

    handleReset() {
        this.dispatchEvent(new CustomEvent('textsizechange', { detail: 'reset' }));
    }

    handleContrast() {
        this.dispatchEvent(new CustomEvent('contrastchange'));
    }

    handleEasyRead() {
        this.dispatchEvent(new CustomEvent('easyreadchange'));
    }
}
