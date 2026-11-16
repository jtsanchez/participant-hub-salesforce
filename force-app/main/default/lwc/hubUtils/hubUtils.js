const DATE_OPTIONS = { day: 'numeric', month: 'long', year: 'numeric' };

/**
 * Parses a Salesforce date ("2026-11-16") as a local date so it never shifts a day
 * because of the time zone. Date-times and timestamps are parsed normally.
 */
export function parseDate(value) {
    if (value === null || value === undefined || value === '') {
        return null;
    }
    const text = String(value);
    const dateOnly = /^(\d{4})-(\d{2})-(\d{2})$/.exec(text);
    if (dateOnly) {
        return new Date(Number(dateOnly[1]), Number(dateOnly[2]) - 1, Number(dateOnly[3]));
    }
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
}

export function formatDate(value) {
    const date = parseDate(value);
    return date ? new Intl.DateTimeFormat('en-AU', DATE_OPTIONS).format(date) : '';
}

export function reduceError(error) {
    const fallback = 'Something went wrong. Please try again.';
    if (!error) {
        return fallback;
    }
    if (Array.isArray(error.body)) {
        return error.body.map((e) => e.message).join(', ') || fallback;
    }
    if (error.body && typeof error.body.message === 'string') {
        return error.body.message;
    }
    if (typeof error.message === 'string') {
        return error.message;
    }
    return fallback;
}
