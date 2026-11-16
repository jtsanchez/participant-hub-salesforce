import { LightningElement } from 'lwc';
import getMyPlan from '@salesforce/apex/ParticipantHubController.getMyPlan';
import { reduceError } from 'c/hubUtils';

const TEXT_SIZES = [1, 1.125, 1.25, 1.5, 1.75];
const STORE_KEY = 'participantHubDisplay';

export default class ParticipantHub extends LightningElement {
    plan;
    error;
    isLoading = true;
    sizeIndex = 0;
    highContrast = false;
    easyRead = false;
    easyReadChosen = false;

    connectedCallback() {
        this.restoreSettings();
        this.loadPlan(false);
    }

    async loadPlan(silent) {
        if (!silent) {
            this.isLoading = true;
        }
        try {
            const result = await getMyPlan();
            this.plan = result || undefined;
            this.error = undefined;
            // Start in Easy Read if the person asked for it, unless they have already chosen here.
            if (this.plan && !this.easyReadChosen) {
                this.easyRead = !!this.plan.easyReadPreferred;
            }
        } catch (error) {
            this.plan = undefined;
            this.error = reduceError(error);
        } finally {
            this.isLoading = false;
        }
    }

    get hasPlan() {
        return !this.isLoading && !this.error && !!this.plan;
    }

    get hasError() {
        return !this.isLoading && !!this.error;
    }

    get showEmpty() {
        return !this.isLoading && !this.error && !this.plan;
    }

    get containerClass() {
        let classes = 'hub';
        if (this.highContrast) {
            classes += ' contrast';
        }
        if (this.easyRead) {
            classes += ' easy';
        }
        return classes;
    }

    get containerStyle() {
        return `--hub-font-size: ${TEXT_SIZES[this.sizeIndex]}rem;`;
    }

    get textSizeLabel() {
        return `${Math.round(TEXT_SIZES[this.sizeIndex] * 100)}%`;
    }

    handleTextSize(event) {
        const action = event.detail;
        if (action === 'increase') {
            this.sizeIndex = Math.min(TEXT_SIZES.length - 1, this.sizeIndex + 1);
        } else if (action === 'decrease') {
            this.sizeIndex = Math.max(0, this.sizeIndex - 1);
        } else {
            this.sizeIndex = 0;
        }
        this.saveSettings();
    }

    handleContrast() {
        this.highContrast = !this.highContrast;
        this.saveSettings();
    }

    handleEasyRead() {
        this.easyRead = !this.easyRead;
        this.easyReadChosen = true;
        this.saveSettings();
    }

    handlePlanChange() {
        this.loadPlan(true);
    }

    restoreSettings() {
        try {
            const raw = window.localStorage.getItem(STORE_KEY);
            if (!raw) {
                return;
            }
            const saved = JSON.parse(raw);
            if (Number.isInteger(saved.sizeIndex) && saved.sizeIndex >= 0 && saved.sizeIndex < TEXT_SIZES.length) {
                this.sizeIndex = saved.sizeIndex;
            }
            this.highContrast = !!saved.highContrast;
            if (typeof saved.easyRead === 'boolean') {
                this.easyRead = saved.easyRead;
                this.easyReadChosen = true;
            }
        } catch (e) {
            // Browser storage can be unavailable. The page works without it.
        }
    }

    saveSettings() {
        try {
            window.localStorage.setItem(
                STORE_KEY,
                JSON.stringify({
                    sizeIndex: this.sizeIndex,
                    highContrast: this.highContrast,
                    easyRead: this.easyReadChosen ? this.easyRead : undefined
                })
            );
        } catch (e) {
            // Ignore storage problems. Display settings just will not be remembered.
        }
    }
}
