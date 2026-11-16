import { LightningElement, api } from 'lwc';
import { formatDate } from 'c/hubUtils';

const TEXT = {
    normal: {
        heading: 'Plan overview',
        hours: 'Support hours per week',
        start: 'Plan starts',
        end: 'Plan ends',
        goals: 'My goals',
        noGoals: 'No goals have been added yet.'
    },
    easy: {
        heading: 'My plan',
        hours: 'Hours of support each week',
        start: 'Starts on',
        end: 'Ends on',
        goals: 'What I want to do',
        noGoals: 'No goals yet.'
    }
};

const PLAN_STATUS_EASY = {
    Active: 'My plan is running',
    'Awaiting Participant Approval': 'My plan is waiting for me to say yes',
    Completed: 'My plan is finished'
};

const GOAL_STATUS_EASY = {
    'Not Started': 'Not started yet',
    'In Progress': 'Working on it',
    Achieved: 'Done!'
};

export default class HubPlanSummary extends LightningElement {
    @api plan;
    @api easyRead = false;

    get t() {
        return this.easyRead ? TEXT.easy : TEXT.normal;
    }

    get statusLabel() {
        const status = this.plan?.status || '';
        return this.easyRead ? PLAN_STATUS_EASY[status] || status : status;
    }

    get hoursText() {
        const hours = this.plan?.hoursPerWeek;
        if (hours === null || hours === undefined) {
            return 'Not set yet';
        }
        return `${Number(hours)} hours`;
    }

    get startText() {
        return formatDate(this.plan?.startDate) || 'Not set yet';
    }

    get endText() {
        return formatDate(this.plan?.endDate) || 'Not set yet';
    }

    get summaryLines() {
        const useEasy = this.easyRead && this.plan?.easyReadSummary;
        const text = (useEasy ? this.plan.easyReadSummary : this.plan?.planSummary) || '';
        return text
            .split(/\r?\n/)
            .map((line) => line.trim())
            .filter((line) => line.length > 0)
            .map((line, index) => ({ key: `line-${index}`, text: line }));
    }

    get noGoals() {
        return !this.plan?.goals || this.plan.goals.length === 0;
    }

    get goals() {
        return (this.plan?.goals || []).map((goal) => {
            const pct = Math.max(0, Math.min(100, Math.round(Number(goal.progressPercent) || 0)));
            return {
                key: goal.recordId,
                name: goal.name,
                description: goal.description,
                showDescription: !this.easyRead && !!goal.description,
                statusText: this.easyRead ? GOAL_STATUS_EASY[goal.status] || goal.status : goal.status,
                pct,
                barStyle: `width: ${pct}%`,
                progressLabel: `${goal.name}: ${pct} percent done`,
                targetText: formatDate(goal.targetDate)
            };
        });
    }
}
