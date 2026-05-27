import { LightningElement, track } from 'lwc';
import getOverviewForCurrentUser from '@salesforce/apex/ARC_OpenEnrollmentAndProgramsController.getOverviewForCurrentUser';

export default class ARC_OpenEnrollmentAndPrograms extends LightningElement {
  isLoading = true;

  oeStart;
  oeEnd;
  oeIsActive = false;

  rawPrograms = [];
  @track programSections = [];

  get hasProgramSections() {
    return Array.isArray(this.programSections) && this.programSections.length > 0;
  }

  async connectedCallback() {
    this.isLoading = true;
    try {
      const data = await getOverviewForCurrentUser();

      this.oeStart = data?.oe?.startDate;
      this.oeEnd = data?.oe?.endDate;
      this.oeIsActive = this.isTodayBetween(this.oeStart, this.oeEnd);

      this.rawPrograms = Array.isArray(data?.programs) ? data.programs : [];
      this.programSections = this.buildSections(this.rawPrograms);

      console.log('Apex data:', JSON.parse(JSON.stringify(data)));
      console.log('Programs length:', this.rawPrograms.length);
    } catch (e) {
      console.error('Apex error:', e?.body?.message || e);
      this.rawPrograms = [];
      this.programSections = [];
    } finally {
      this.isLoading = false;
    }
  }

  isTodayBetween(startStr, endStr) {
    if (!startStr || !endStr) return false;

    const parseYMD = (s) => {
      const m = String(s).match(/^(\d{4})-(\d{2})-(\d{2})/);
      if (!m) return null;
      return new Date(parseInt(m[1], 10), parseInt(m[2], 10) - 1, parseInt(m[3], 10));
    };

    const start = parseYMD(startStr);
    const end = parseYMD(endStr);
    if (!start || !end) return false;

    const t = new Date();
    const today = new Date(t.getFullYear(), t.getMonth(), t.getDate());

    return today >= start && today <= end;
  }

  get oeStartFormatted() {
    return this.formatDate(this.oeStart);
  }

  get oeEndFormatted() {
    return this.formatDate(this.oeEnd);
  }

  formatDate(d) {
    if (!d) return '—';

    const s = typeof d === 'string' ? d : String(d);

    const m = s.match(/^(\d{4})-(\d{2})-(\d{2})/);
    if (m) {
      const year = parseInt(m[1], 10);
      const month = parseInt(m[2], 10) - 1;
      const day = parseInt(m[3], 10);
      const dt = new Date(year, month, day);
      return new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      }).format(dt);
    }

    const dt = new Date(s);
    if (Number.isNaN(dt.getTime())) return '—';

    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    }).format(dt);
  }

  toggleSection(event) {
    const key = event.currentTarget.dataset.key;
    this.programSections = this.programSections.map((s) => {
      if (s.key !== key) return s;
      const open = !s.open;
      return {
        ...s,
        open,
        chevronClass: open ? 'chevron up' : 'chevron'
      };
    });
  }

  buildSections(programs = []) {
    const groups = new Map();

    programs.forEach((p) => {
      const groupKey = this.getProgramGroupKey(p);

      if (!groups.has(groupKey)) {
        groups.set(groupKey, {
          key: groupKey,
          title: groupKey,
          description: '',
          open: false,
          chevronClass: 'chevron',
          plans: []
        });
      }

      groups.get(groupKey).plans.push(this.toPlanCard(p));
    });

    let result = Array.from(groups.values()).map((section) => {
      return {
        ...section,
        plans: this.sortPlansByCategory(section.plans)
      };
    });

    result = this.sortSectionsByCategory(result);

    result = result.map((s) => ({ ...s, open: true, chevronClass: 'chevron up' }));

    return result;
  }

  getProgramGroupKey(p) {
    const name = (p?.name || '').trim();
    if (!name) return 'Programs';

    let base = name
      .replace(/\b\d+\s*k\b/gi, '')
      .split(' - ')[0]
      .split(':')[0]
      .trim();

    base = base.replace(/\s{2,}/g, ' ');

    return base || 'Programs';
  }

  getCategoryFromString(s = '') {
    const t = (s || '').toLowerCase();

    if (t.includes('premier')) return 'Premier';
    if (t.includes('essential')) return 'Essential';
    if (t.includes('enhanced')) return 'Enhanced';
    if (t.includes('senior')) return 'Senior';

    return 'Other';
  }

  extractK(s = '') {
    const m = (s || '').toLowerCase().match(/(\d+)\s*k/);
    return m ? parseInt(m[1], 10) : 9999;
  }

  sortSectionsByCategory(sections = []) {
     const order = {
      Premier: 1,
      Enhanced: 2,
      Essential: 3,
      Senior: 4,
      Other: 99
    };

    return [...sections].sort((a, b) => {
      const catA = this.getCategoryFromString(a.title || '');
      const catB = this.getCategoryFromString(b.title || '');

      const orderA = order[catA] ?? 99;
      const orderB = order[catB] ?? 99;

      if (orderA !== orderB) {
        return orderA - orderB;
      }

      const kA = this.extractK(a.title || '');
      const kB = this.extractK(b.title || '');

      if (catA !== 'Senior' && kA !== kB) {
        return kA - kB;
      }

      return (a.title || '').localeCompare(b.title || '', undefined, {
        sensitivity: 'base'
      });
    });
  }

  sortPlansByCategory(plans = []) {
    const order = {
      Premier: 1,
      Enhanced: 2,
      Essential: 3,
      Senior: 4,
      Other: 99
    };

    return [...plans]
      .map((p) => {
        const cat = this.getCategoryFromString(`${p.title || ''} ${p.code || ''}`);
        const k = this.extractK(`${p.title || ''} ${p.code || ''}`);
        return { ...p, category: cat, kValue: k };
      })
      .sort((a, b) => {
        const oa = order[a.category] ?? 99;
        const ob = order[b.category] ?? 99;

        if (oa !== ob) return oa - ob;
        if (a.category !== 'Senior' && a.kValue !== b.kValue) return a.kValue - b.kValue;

        return (a.title || '').localeCompare(b.title || '', undefined, {
          sensitivity: 'base'
        });
      });
  }

  amountFromCodeOrName(code = '', name = '') {
    const s = (code || name || '').toLowerCase();

    if (s.includes('senior')) return '$500.00';

    if (s.includes('1k')) return '$1,000/$2,000';
    if (s.includes('3k')) return '$3,000/$6,000';
    if (s.includes('5k')) return '$5,000/$10,000';
    if (s.includes('6k')) return '$6,000/$12,000';
    if (s.includes('9k')) return '$9,000/$18,000';
    if (s.includes('10k')) return '$10,000/$20,000';
    if (s.includes('12k')) return '$12,000/$24,000';

    return '—';
  }

  toPlanCard(p) {
    const title = p?.name || 'Program';
    const offered = !!p?.offered;
    const category = this.getCategoryFromString(`${title} ${p?.code || ''}`);

    return {
      productId: p?.productId,
      title,
      offered,
      pillText: offered ? 'Offered' : 'Not Offered',
      pillClass: offered ? 'pill pillOffered' : 'pill pillNotOffered',
      meta: category === 'Senior' ? 'AMCS Individual' : 'AMCS Individual/ Family',
      value: this.amountFromCodeOrName(p?.code, title),
      code: p?.code
    };
  }
}