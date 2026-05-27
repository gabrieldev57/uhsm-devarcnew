import { LightningElement, api, wire } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGroupClassFromOpportunity from '@salesforce/apex/aRC_employerContributionController.getGroupClassFromOpportunity';
import resetGroupClasses from '@salesforce/apex/aRC_employerContributionController.resetGroupClasses';
import saveGroupClassConfiguration from '@salesforce/apex/aRC_employerContributionController.saveGroupClassConfiguration';

const EMPLOYEE_TIERS = [
  { key: 'EMP_ONLY', label: 'Employee Only' },
  { key: 'EMP_PLUS_ONE', label: 'Employee +1' },
  { key: 'FAMILY', label: 'Family' }
];

export default class ARC_employerContributionConfiguration extends LightningElement {
  @api recordId;
  @api refreshKey;

  loading = true;
  errorMessage = '';
  groupClasses = [];
  savingGcId = null;

  showResetModal = false;

  @wire(getGroupClassFromOpportunity, { opportunityId: '$recordId', cacheBuster: '$refreshKey' })
  wiredGroupClasses({ data, error }) {
    this.loading = false;

    if (data) {
      console.log('getGroupClassFromOpportunity payload:', JSON.parse(JSON.stringify(data)));

      const list = data?.groupClases || data?.groupClasses || [];
      this.groupClasses = (list || []).map((gc) => this.mapServerGroupClassToUi(gc));

      const cliResult = data.cliComparisonResult ?? 'FIRST_TIME';
      if (cliResult !== 'FIRST_TIME') {
        this.groupClasses = this.groupClasses.map((gc) =>
          !gc.hasContributions ? this.applyRenewalTransform(gc, cliResult) : gc
        );
      }

      this.errorMessage = '';
      return;
    }

    if (error) {
      this.groupClasses = [];
      this.errorMessage = this.normalizeError(error);
      this.toastError(this.errorMessage);
    }
  }

  get hasGroupClasses() {
    return (this.groupClasses || []).length > 0;
  }

  get groupClassesUi() {
  return (this.groupClasses || []).map((gc) => {
    const readonly = !!gc.readOnly;

    const programBasedYes = gc.programBased === 'YES';
    const disableLowestCostOptions = programBasedYes;

    const cardClass = gc.expanded ? 'groupCard expanded' : 'groupCard';
    const chevronIcon = gc.expanded ? 'utility:chevrondown' : 'utility:chevronright';
    const iconWrapClass = gc.expanded ? 'iconWrap active' : 'iconWrap';

        const effectiveModel = gc.employeeTypeModel || 'None';

    const isFtPtLocked =
      gc.lockFtPt && effectiveModel === 'FullTime_PartTime';
    const isExemptLocked =
      gc.lockExempt && effectiveModel === 'Exempt_NonExempt';

    const modelFtPtClass =
      effectiveModel === 'FullTime_PartTime' && !isFtPtLocked
        ? 'optBtn selected'
        : 'optBtn';

    const modelExemptClass =
      effectiveModel === 'Exempt_NonExempt' && !isExemptLocked
        ? 'optBtn selected'
        : 'optBtn';

    const modelNoneClass =
      effectiveModel === 'None' || isFtPtLocked || isExemptLocked
        ? 'optBtn selected'
        : 'optBtn';

    const depYesClass = gc.dependentDiff === 'YES' ? 'optBtn selected' : 'optBtn';
    const depNoClass = gc.dependentDiff === 'NO' ? 'optBtn selected' : 'optBtn';

    const pbYesClass = gc.programBased === 'YES' ? 'optBtn selected' : 'optBtn';
    const pbNoClass = gc.programBased === 'NO' ? 'optBtn selected' : 'optBtn';

    const ctFlatAmtClass =
      gc.contributionMethod === 'Flat_Amount' ? 'optBtn selected' : 'optBtn';
    const ctFlatPctClass =
      gc.contributionMethod === 'Flat_Percentage' ? 'optBtn selected' : 'optBtn';
    const ctLowestCostClass =
      gc.contributionMethod === 'Percent_Of_Lowest_Cost' ? 'optBtn selected' : 'optBtn';
    const ctLowestByCatClass =
      gc.contributionMethod === 'Percent_Of_Lowest_By_Category' ? 'optBtn selected' : 'optBtn';

    const showModelInfo = true;
    const modelInfoText =
      gc.employeeTypeModel === 'FullTime_PartTime'
        ? 'Members will be segmented by Full Time / Part Time.'
        : gc.employeeTypeModel === 'Exempt_NonExempt'
        ? 'Members will be segmented by Exempt / Non-Exempt.'
        : 'No segmentation will be applied for contributions.';

    const available = gc.availablePrograms || [];
    const selected = gc.selectedPrograms || [];

    const pickedAvailable = new Set(gc.pickedAvailable || []);
    const pickedSelected = new Set(gc.pickedSelected || []);

    const availableProgramsUi = available.map((p) => ({
      ...p,
      cardClass: pickedAvailable.has(p.id) ? 'programCard picked' : 'programCard'
    }));

    const selectedProgramsUi = selected.map((p) => ({ ...p }));

    const selectedCount = selected.length;
    const disableAdd = pickedAvailable.size === 0;
    const disableRemove = pickedSelected.size === 0;

    const matrixUi = this.buildMatrixUi(gc);

    const saveBtnLabel = readonly ? 'Edit Configuration' : 'Save Configuration';
    const saveBtnVariant = readonly ? 'neutral' : 'brand';

    const disableModelFtPt = !!gc.lockFtPt || readonly;
    const disableModelExempt = !!gc.lockExempt || readonly;
    const disableModelNone = readonly;

    const disableFlatPct = readonly;

    const disableLowestCost = !!disableLowestCostOptions || readonly;
    const disableLowestByCat = !!disableLowestCostOptions || readonly;

    const disableAddSelected = !!disableAdd || readonly;
    const disableRemoveSelected = !!disableRemove || readonly;

    const normalizeName = (s) =>
      (s || '')
        .toLowerCase()
        .replace(/[–—]/g, '-')
        .replace(/\s+/g, ' ')
        .trim();

    const nameNorm = normalizeName(gc.name);

    const BLUE = '#2563eb';
    const GRAY = '#6b7280';
    const ORANGE = '#f59e0b';

    const isNone = nameNorm === 'none' || nameNorm === 'general' || nameNorm.includes('none');
    const isPartTime = nameNorm.includes('part time');
    const isNonExempt =
      nameNorm.includes('non-exempt') || nameNorm.includes('non exempt') || nameNorm.includes('nonexempt');

    const iconColor =
      isNone ? BLUE :
      isPartTime && isNonExempt ? ORANGE :
      isPartTime ? GRAY :
      BLUE;

    const iconBgStyle = `background-color: ${iconColor};`;
    const iconStyle = `--slds-c-icon-color-foreground-default: #ffffff;`;

    const isCompleted = !!gc.isCompleted;
    const statusLabel = isCompleted ? 'Completed' : 'Pending';
    const statusClass = isCompleted ? 'statusBadge statusCompleted' : 'statusBadge statusPending';
    const statusIcon = isCompleted ? 'utility:success' : 'utility:clock';

    return {
      ...gc,
      readonly,

      cardClass,
      chevronIcon,
      iconWrapClass,

      modelFtPtClass,
      modelExemptClass,
      modelNoneClass,

      depYesClass,
      depNoClass,

      pbYesClass,
      pbNoClass,

      ctFlatAmtClass,
      ctFlatPctClass,
      ctLowestCostClass,
      ctLowestByCatClass,

      disableLowestCostOptions,
      showModelInfo,
      modelInfoText,

      availableProgramsUi,
      selectedProgramsUi,
      selectedCount,
      disableAdd,
      disableRemove,

      matrixUi,

      saveBtnLabel,
      saveBtnVariant,

      disableModelFtPt,
      disableModelExempt,
      disableModelNone,

      disableFlatPct,
      disableLowestCost,
      disableLowestByCat,

      disableAddSelected,
      disableRemoveSelected,

      iconBgStyle,
      iconStyle,

      statusLabel,
      statusClass,
      statusIcon,
      isCompleted
    };
  });
  }

  applyRenewalTransform(gc, cliResult) {
    if (cliResult === 'MATCH') {
      // Pre-fill from prior contract settings; force Pending so AM must review and save
      const priorSettings = gc.priorSettings || {};
      const priorContribsByProductId = gc.priorContribsByProductId || {};

      const contributionMethod = priorSettings.contributionMethod || gc.contributionMethod || 'Flat_Amount';
      const programBased = priorSettings.applyProgramBased ? 'YES' : 'NO';
      const dependentDiff = priorSettings.applyEmployeeTier ? 'YES' : 'NO';

      // Re-map all programs: inject prior contributions matched by productId
      const allPrograms = [...(gc.selectedPrograms || []), ...(gc.availablePrograms || [])];
      const selectedPrograms = allPrograms.map((p) => {
        const priorContribs = priorContribsByProductId[p.productId] || [];
        return { ...p, contributions: priorContribs, hasContributions: priorContribs.length > 0 };
      });

      const matrixValues = this.hydrateMatrixValuesFromPrograms({
        employeeTypeModel: gc.employeeTypeModel,
        dependentDiff,
        programBased,
        programs: selectedPrograms
      });

      return {
        ...gc,
        isCompleted: false,
        readOnly: false,
        hasContributions: false,
        contributionMethod,
        programBased,
        dependentDiff,
        selectedPrograms,
        availablePrograms: [],
        matrixValues
      };
    }
    if (cliResult === 'MISMATCH') {
      // Keep GC type structure, clear all configuration so AM starts from scratch
      return {
        ...gc,
        isCompleted: false,
        readOnly: false,
        hasContributions: false,
        contributionMethod: 'Flat_Amount',
        programBased: 'NO',
        dependentDiff: 'NO',
        selectedPrograms: [],
        availablePrograms: [...(gc.selectedPrograms || []), ...(gc.availablePrograms || [])],
        matrixValues: {}
      };
    }
    return gc;
  }

  mapServerGroupClassToUi(gc) {
  const id = gc.Id || gc.id;
  const name = gc.Name || gc.name;

  const employeeType = gc.ARC_EmployeeType__c;
  const employeeDivision = gc.ARC_EmployeeDivision__c;
  const subtitle = this.buildSubtitle(employeeType, employeeDivision);

  const et = (employeeType || '').toLowerCase();
  const ed = (employeeDivision || '').toLowerCase();

  const hasFtPt =
    et.includes('full') ||
    et.includes('part') ||
    et.includes('full time') ||
    et.includes('part time') ||
    et === 'ft' ||
    et === 'pt';

  const hasExempt =
    ed.includes('exempt') ||
    ed.includes('non-exempt') ||
    ed.includes('non exempt') ||
    ed === 'exempt' ||
    ed === 'non-exempt';

  const lockFtPt = hasFtPt;
  const lockExempt = hasExempt;
  const lockNone = false;

  const employeeTypeModel = gc.ARC_EmployeeTypeModel__c || 'None';

  const dependentDiff = gc.ARC_ApplyEmployeeTier__c ? 'YES' : 'NO';
  const programBased = gc.ARC_ApplyProgramBased__c ? 'YES' : 'NO';
  const contributionMethod = gc.ARC_ContributionMethod__c || 'Flat_Amount';

  const showLockedWarning = lockFtPt || lockExempt;

  const lockedWarningText =
    lockFtPt && lockExempt
      ? `Employee Type options are disabled because this Group Class is already defined as ${subtitle}.`
      : lockFtPt
      ? 'The Full Time / Part Time options is disabled because it is already defined as part of this Group Class.'
      : lockExempt
      ? 'The Exempt / Non-Exempt options is disabled because it is already defined as part of this Group Class.'
      : '';

  const programs = gc.programs || [];

  const normalizeProgram = (p) => {
    const programId = p.contractLineItemId || p.contractLineitemId || p.id;
    const programName = p.productName || p.prductName || p.name;
    const programDesc = p.description || p.desc || '';
    const productId = p.productId || p.vlocity_ins__Product2Id__c || null;

    const productCategory =
      p.vlocity_ins__ProductCategory__c ||
      p.vlocity_ins__ProductType__c ||
      p.productCategory ||
      p.productType ||
      null;

    return {
      id: programId,
      name: programName,
      description: programDesc,
      productId,
      productCategory,
      hasContributions: !!p.hasContributions,
      contributions: p.contributions || []
    };
  };

  const normalized = programs.map(normalizeProgram);

  const selectedPrograms = normalized.filter((p) => p.hasContributions === true);
  const availablePrograms = normalized.filter((p) => p.hasContributions !== true);

  const matrixValues = this.hydrateMatrixValuesFromPrograms({
    employeeTypeModel,
    dependentDiff,
    programBased,
    programs: normalized
  });

  const isCompleted = !!gc.hasContributions;

  return {
    id,
    name,
    subtitle,

    employeeType,
    employeeDivision,
    hasContributions: isCompleted,

    expanded: false,

    employeeTypeModel,
    dependentDiff,
    programBased,
    contributionMethod,

    availablePrograms,
    selectedPrograms,

    pickedAvailable: [],
    pickedSelected: [],

    matrixValues,

    readOnly: isCompleted,

    lockFtPt,
    lockExempt,
    lockNone,
    showLockedWarning,
    lockedWarningText,

    isCompleted,

    priorSettings: gc.priorSettings || null,
    priorContribsByProductId: gc.priorContribsByProductId || {}
  };
}


  hydrateMatrixValuesFromPrograms({ employeeTypeModel, dependentDiff, programBased, programs }) {
    const values = {};

    const tierToColKey = (tierLabel) => {
      const t = (tierLabel || '').toLowerCase();
      if (t.includes('only')) return 'EMP_ONLY';
      if (t.includes('+1') || t.includes('plus one')) return 'EMP_PLUS_ONE';
      if (t.includes('family')) return 'FAMILY';
      return 'EMP_ONLY';
    };

    const normSegKey = (raw, model) => {
      const v = (raw || '').toLowerCase();

      if (model === 'FullTime_PartTime') {
        if (v.includes('full')) return 'FULL_TIME';
        if (v.includes('part')) return 'PART_TIME';
      }

      if (model === 'Exempt_NonExempt') {
        if (v.includes('non')) return 'NON_EXEMPT';
        if (v.includes('exempt')) return 'EXEMPT';
      }

      return null;
    };

    (programs || []).forEach((p) => {
      (p.contributions || []).forEach((c) => {
        let rowKey = 'GC';

        const segKey =
          employeeTypeModel === 'FullTime_PartTime'
            ? normSegKey(c.ARC_EmployeeType__c, employeeTypeModel)
            : employeeTypeModel === 'Exempt_NonExempt'
            ? normSegKey(c.ARC_EmployeeDivision__c, employeeTypeModel)
            : null;

        if (programBased === 'YES' && p.id) {
          rowKey = segKey ? `PROG:${p.id}__SEG:${segKey}` : `PROG:${p.id}`;
        } else {
          rowKey = segKey ? `SEG:${segKey}` : 'GC';
        }

        const colKey = dependentDiff === 'YES' ? tierToColKey(c.ARC_EmployeeTier__c) : 'SINGLE';
        const cellKey = `${rowKey}|${colKey}`;

        const pct = c.vlocity_ins__ContributionPercent__c;
        const amt = c.vlocity_ins__ContributionAmount__c;

        const val = pct != null ? pct : amt != null ? amt : '';
        values[cellKey] = val;
      });
    });

    return values;
  }

  buildMatrixUi(gc) {
    const programBased = gc.programBased === 'YES';
    const hasTiers = gc.dependentDiff === 'YES';
    const model = gc.employeeTypeModel || 'None';

    const selectedPrograms = gc.selectedPrograms || [];

    const showLowestCostWarning = gc.contributionMethod === 'Percent_Of_Lowest_Cost';

    if (programBased && selectedPrograms.length === 0) {
      return {
        hasRows: false,
        headers: [],
        rows: [],
        valuePrefix: '',
        valueSuffix: '',
        showLowestCostWarning
      };
    }

    const cols = hasTiers ? EMPLOYEE_TIERS : [{ key: 'SINGLE', label: 'Contribution' }];
    const headers = [{ key: 'ROW', label: '' }, ...cols.map((c) => ({ key: c.key, label: c.label }))];
    const segmentRows = this.getSegmentRowsForGroupClass(gc);

    const isNoSegCase = model === 'None' && gc.dependentDiff === 'NO' && gc.programBased === 'NO';

    const rows = [];

    const addRow = (rowKey, rowLabel) => {
      const cells = [];

      cells.push({
        key: `${rowKey}|LABEL`,
        isLabel: true,
        label: rowLabel,
        tdClass: 'matrixLabelCell',
        cellKey: null,
        value: null
      });

      cols.forEach((col) => {
        const cellKey = `${rowKey}|${col.key}`;
        const value = (gc.matrixValues || {})[cellKey] ?? '';

        cells.push({
          key: cellKey,
          isLabel: false,
          label: col.label,
          tdClass: 'matrixValueCell',
          cellKey,
          value
        });
      });

      rows.push({ key: rowKey, cells });
    };

    if (isNoSegCase) {
      addRow('GC', gc.name || 'Group Class');
    } else if (programBased) {
      selectedPrograms.forEach((p) => {
        if (!segmentRows.length) {
          addRow(`PROG:${p.id}`, p.name);
        } else {
          segmentRows.forEach((seg) => {
            addRow(`PROG:${p.id}__SEG:${seg.key}`, `${p.name} — ${seg.label}`);
          });
        }
      });
    } else {
      if (!segmentRows.length) {
        addRow('GC', gc.name || 'Group Class');
      } else {
        segmentRows.forEach((seg) => addRow(`SEG:${seg.key}`, seg.label));
      }
    }

    const isPercent =
      gc.contributionMethod === 'Flat_Percentage' ||
      gc.contributionMethod === 'Percent_Of_Lowest_Cost' ||
      gc.contributionMethod === 'Percent_Of_Lowest_By_Category';

    const valuePrefix = gc.contributionMethod === 'Flat_Amount' ? '$' : '';
    const valueSuffix = isPercent ? '%' : '';

    return {
      hasRows: rows.length > 0,
      headers,
      rows,
      valuePrefix,
      valueSuffix,
      showLowestCostWarning
    };
  }

  getSegmentRowsForGroupClass(gc) {
    const model = gc.employeeTypeModel || 'None';
    if (model === 'None') return [];

    const gcEmpType = (gc.employeeType || '').toLowerCase();

    if (model === 'FullTime_PartTime') {
      if (gcEmpType.includes('full')) return [{ key: 'FULL_TIME', label: 'Full Time' }];
      if (gcEmpType.includes('part')) return [{ key: 'PART_TIME', label: 'Part Time' }];
      return [
        { key: 'FULL_TIME', label: 'Full Time' },
        { key: 'PART_TIME', label: 'Part Time' }
      ];
    }

    if (model === 'Exempt_NonExempt') {
      const div = (gc.employeeDivision || '').toLowerCase();

      const isNonExempt =
        div.includes('non-exempt') ||
        div.includes('non exempt') ||
        div.includes('nonexempt');

      const isExempt = div.includes('exempt') && !isNonExempt;

      if (isNonExempt) return [{ key: 'NON_EXEMPT', label: 'Non-Exempt' }];
      if (isExempt) return [{ key: 'EXEMPT', label: 'Exempt' }];

      return [
        { key: 'EXEMPT', label: 'Exempt' },
        { key: 'NON_EXEMPT', label: 'Non-Exempt' }
      ];
    }

    return [];
  }

  handleMatrixValueChange = (e) => {
    const gcId = e.target?.dataset?.gcid;
    const cellKey = e.target?.dataset?.cellkey;
    const value = e.detail?.value ?? e.target?.value ?? '';

    if (!gcId || !cellKey) return;

    this.groupClasses = (this.groupClasses || []).map((gc) => {
      if (gc.id !== gcId) return gc;
      if (gc.readOnly) return gc;

      const nextValues = { ...(gc.matrixValues || {}) };
      nextValues[cellKey] = value;

      return { ...gc, matrixValues: nextValues };
    });
  };

  buildSavePayloadForGroupClass(gc) {
    return this.buildSavePayloadForGroupClassApex(gc);
  }

  buildSavePayloadForGroupClassApex(gc) {
    const programs = this.buildProgramsForSaveApex(gc);

    return {
      Id: gc.id,
      Name: gc.name,

      ARC_EmployeeTypeModel__c: gc.employeeTypeModel || 'None',
      ARC_EmployeeType__c: gc.employeeType || 'None',
      ARC_EmployeeDivision__c: gc.employeeDivision || 'None',

      ARC_ApplyProgramBased__c: gc.programBased === 'YES',
      ARC_ApplyEmployeeTier__c: gc.dependentDiff === 'YES',
      ARC_ContributionMethod__c: gc.contributionMethod || 'Flat_Amount',

      hasContributions: programs.some((p) => (p.contributions || []).length > 0),
      programs
    };
  }

  buildProgramsForSaveApex(gc) {
    const allPrograms = [...(gc.availablePrograms || []), ...(gc.selectedPrograms || [])];
    const contribsByCliId = this.buildContribsByCliIdForSaveApex(gc, allPrograms);

    return allPrograms.map((p) => {
      const cliId = p.id || null;
      return {
        productName: p.name,
        contractLineItemId: cliId,
        productId: p.productId || null,
        vlocity_ins__ProductCategory__c: p.productCategory || null,
        hasContributions: (contribsByCliId.get(cliId) || []).length > 0,
        contributions: contribsByCliId.get(cliId) || []
      };
    });
  }

  buildContribsByCliIdForSaveApex(gc, allPrograms) {
  const applyProgramBased = gc.programBased === 'YES';
  const applyTier = gc.dependentDiff === 'YES';
  const model = gc.employeeTypeModel || 'None';

  const allProgramIds = (allPrograms || []).map((p) => p.id).filter(Boolean);
  const selectedProgramIds = (gc.selectedPrograms || [])
    .map((p) => p.id)
    .filter(Boolean);

  const baseProgramIds =
    applyProgramBased
      ? allProgramIds
      : (selectedProgramIds.length > 0 ? selectedProgramIds : allProgramIds);

  const byCliId = new Map();
  baseProgramIds.forEach((id) => byCliId.set(id, []));

  const tierLabelByKey = {
    EMP_ONLY: 'Employee Only',
    EMP_PLUS_ONE: 'Employee Plus One',
    FAMILY: 'Family',
    SINGLE: 'None'
  };

  const isPercentMethod =
    gc.contributionMethod === 'Flat_Percentage' ||
    gc.contributionMethod === 'Percent_Of_Lowest_Cost' ||
    gc.contributionMethod === 'Percent_Of_Lowest_By_Category';

  const contribType = isPercentMethod ? 'Percent' : 'Amount';

  const toNumber = (v) => {
    if (v === '' || v == null) return null;
    const n = Number(v);
    return Number.isFinite(n) ? n : null;
  };

  const segmentToEmployeeType = (seg) => {
    if (seg === 'FULL_TIME') return 'Full Time';
    if (seg === 'PART_TIME') return 'Part Time';
    return null;
  };

  const segmentToDivision = (seg) => {
    if (seg === 'EXEMPT') return 'Exempt';
    if (seg === 'NON_EXEMPT') return 'Non-Exempt';
    return null;
  };

  const parseRowKey = (rowKey) => {
    let programId = null;
    let segmentKey = null;

    if ((rowKey || '').startsWith('PROG:')) {
      const parts = rowKey.split('__SEG:');
      programId = (parts[0] || '').replace('PROG:', '') || null;
      segmentKey = parts[1] || null;
    } else if ((rowKey || '').startsWith('SEG:')) {
      segmentKey = (rowKey || '').replace('SEG:', '') || null;
    } else if ((rowKey || '') === 'GC' || (rowKey || '').startsWith('GC_')) {
      segmentKey = null;
    }

    return { programId, segmentKey };
  };

  const buildContribName = ({ programName, empType, empDiv, empTier }) => {
    const parts = [];
    if (programName) parts.push(programName);
    if (empType && empType !== 'None') parts.push(empType);
    if (empDiv && empDiv !== 'None') parts.push(empDiv);
    if (empTier && empTier !== 'None') parts.push(empTier);
    return parts.join(' - ');
  };

  const cliIdToCategory = new Map();
  (allPrograms || []).forEach((p) => {
    const pid = p.id || null;
    if (!pid) return;
    const cat = p.productCategory || null;
    if (cat) cliIdToCategory.set(pid, cat);
  });

  const matrixUi = this.buildMatrixUi(gc);
  const rows = matrixUi.rows || [];

  rows.forEach((r) => {
    const rowKey = r.key || '';
    const { programId: rowProgramId, segmentKey } = parseRowKey(rowKey);

    const baseEmpType = gc.employeeType || 'None';
    const baseEmpDiv = gc.employeeDivision || 'None';

    const segEmpType = model === 'FullTime_PartTime' ? segmentToEmployeeType(segmentKey) : null;
    const segEmpDiv = model === 'Exempt_NonExempt' ? segmentToDivision(segmentKey) : null;

    const empType = segEmpType || baseEmpType;
    const empDiv = segEmpDiv || baseEmpDiv;

    const targetProgramIds = applyProgramBased
      ? (rowProgramId ? [rowProgramId] : [])
      : baseProgramIds;

    if (!targetProgramIds.length) return;

    (r.cells || []).slice(1).forEach((c) => {
      const cellKey = c.cellKey;
      const rawVal = (gc.matrixValues || {})[cellKey];
      const valueNum = toNumber(rawVal);
      if (valueNum == null) return;

      const colKey = (cellKey || '').split('|')[1] || 'SINGLE';
      const empTier = applyTier ? (tierLabelByKey[colKey] || 'None') : 'None';

      targetProgramIds.forEach((pid) => {
        if (!pid) return;

        const programName = allPrograms.find((p) => p.id === pid)?.name || null;
        const productCategory = cliIdToCategory.get(pid) || null;

        const contrib = {
          id: null,
          Name: buildContribName({ programName, empType, empDiv, empTier }),
          vlocity_ins__ProductCategory__c: productCategory,
          ARC_EmployeeType__c: empType,
          ARC_EmployeeDivision__c: empDiv,
          ARC_EmployeeTier__c: empTier,
          vlocity_ins__ContributionType__c: contribType,
          vlocity_ins__ContributionPercent__c: contribType === 'Percent' ? valueNum : null,
          vlocity_ins__ContributionAmount__c: contribType === 'Amount' ? valueNum : null
        };

        if (!byCliId.has(pid)) byCliId.set(pid, []);
        byCliId.get(pid).push(contrib);
      });
    });
  });

  byCliId.forEach((list, pid) => {
    const dedup = new Map();
    (list || []).forEach((c) => {
      const k = [
        c.ARC_EmployeeType__c || '',
        c.ARC_EmployeeDivision__c || '',
        c.ARC_EmployeeTier__c || '',
        c.vlocity_ins__ContributionType__c || ''
      ].join('|');
      dedup.set(k, c);
    });
    byCliId.set(pid, Array.from(dedup.values()));
  });

  return byCliId;
  }


  hasMatrixContributionData(gc) {
    const matrixUi = this.buildMatrixUi(gc);
    if (!matrixUi?.hasRows) return false;

    const rows = matrixUi.rows || [];
    const values = gc.matrixValues || {};

    for (const r of rows) {
      const cells = (r.cells || []).slice(1);
      for (const c of cells) {
        const key = c.cellKey;
        if (!key) continue;

        let v = values[key];
        if (v == null) continue;

        if (typeof v === 'string') v = v.trim();
        if (v === '') continue;

        const n = Number(v);
        if (Number.isFinite(n)) return true;
      }
    }

    return false;
  }

  toastMatrixMissing() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Error',
        message: 'You need to add contributions data into the matrix.',
        variant: 'error'
      })
    );
  }

  toastProgramsMissing() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Error',
        message: 'You need to select at least one program',
        variant: 'error'
      })
    );
  }

  handleSaveSingle = async (e) => {
  const gcId = e.currentTarget?.dataset?.id;
  if (!gcId) return;

  const gc = (this.groupClasses || []).find((x) => x.id === gcId);
  if (!gc) {
    this.toastError('Group Class not found in UI state.');
    return;
  }

  if (gc.readOnly) {
    this.groupClasses = (this.groupClasses || []).map((x) => {
      if (x.id !== gcId) return x;
      return { ...x, readOnly: false };
    });
    return;
  }

  const selectedPrograms = gc.selectedPrograms || [];
  if (selectedPrograms.length === 0) {
    this.toastProgramsMissing();
    return;
  }

  if (!this.hasMatrixContributionData(gc)) {
    this.toastMatrixMissing();
    return;
  }

  const payload = {
    opportunityId: this.recordId,
    groupClasses: [this.buildSavePayloadForGroupClassApex(gc)]
  };

  console.log('SAVE CONFIGURATION payload:', JSON.parse(JSON.stringify(payload)));

  this.groupClasses = (this.groupClasses || []).map((x) => {
    if (x.id !== gcId) return x;
    return { ...x, isSaving: true };
  });

  this.loading = true;
  try {
    const payloadJson = JSON.stringify(payload);
    const saved = await saveGroupClassConfiguration({ payloadJson });

    console.log('SAVE SINGLE response:', JSON.parse(JSON.stringify(saved)));

    this.groupClasses = (this.groupClasses || []).map((x) => {
      if (x.id !== gcId) return x;
      return {
        ...x,
        hasContributions: true,
        isCompleted: true,
        readOnly: true,
        expanded: false,
        isSaving: false
      };
    });

    await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Saved',
        message: 'Group Class saved successfully.',
        variant: 'success'
      })
    );
  } catch (err) {
    this.toastError(this.normalizeError(err));
  } finally {
    this.loading = false;
    this.groupClasses = (this.groupClasses || []).map((x) => {
      if (x.id !== gcId) return x;
      return { ...x, isSaving: false };
    });
  }
};

  handleBack = () => {
    this.dispatchEvent(new CustomEvent('changegroupclasses', { bubbles: true, composed: true }));
  };

  openResetModal = () => {
    this.showResetModal = true;
  };

  closeResetModal = () => {
    this.showResetModal = false;
  };

  confirmReset = async () => {
  if (!this.recordId) {
    this.toastError('Missing Opportunity recordId.');
    return;
  }

  this.loading = true;
  try {
    await resetGroupClasses({ opportunityId: this.recordId });

    await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Reset complete',
        message: 'Group Classes were deleted. You can define them again.',
        variant: 'success'
      })
    );

    this.showResetModal = false;

    this.dispatchEvent(new CustomEvent('changegroupclasses', { bubbles: true, composed: true }));
  } catch (e) {
    this.toastError(this.normalizeError(e));
  } finally {
    this.loading = false;
  }
};

  stopProp = (e) => {
    e.stopPropagation();
  };

  toggleCard = (e) => {
    const id = e.currentTarget?.dataset?.id;
    if (!id) return;

    this.groupClasses = (this.groupClasses || []).map((gc) => {
      if (gc.id !== id) return gc;
      return { ...gc, expanded: !gc.expanded };
    });
  };

  selectOption = (e) => {
    const id = e.currentTarget?.dataset?.id;
    const field = e.currentTarget?.dataset?.field;
    const value = e.currentTarget?.dataset?.value;
    if (!id || !field) return;

    this.groupClasses = (this.groupClasses || []).map((gc) => {
      if (gc.id !== id) return gc;
      if (gc.readOnly) return gc;

      const next = { ...gc };

      if (field === 'employeeTypeModel') next.employeeTypeModel = value;
      if (field === 'dependentDiff') next.dependentDiff = value;

      if (field === 'programBased') {
        next.programBased = value;

        if (value === 'YES') {
          const isBlockedWhenProgramBased =
            next.contributionMethod === 'Percent_Of_Lowest_Cost' ||
            next.contributionMethod === 'Percent_Of_Lowest_By_Category';

          if (isBlockedWhenProgramBased) next.contributionMethod = 'Flat_Amount';
        }
      }

      if (field === 'contributionMethod') {
        const programBasedYes = next.programBased === 'YES';

        const isBlockedWhenProgramBased =
          value === 'Percent_Of_Lowest_Cost' || value === 'Percent_Of_Lowest_By_Category';

        if (programBasedYes && isBlockedWhenProgramBased) return next;

        next.contributionMethod = value;
      }

      return next;
    });
  };

  toggleProgramPick = (e) => {
    const gcId = e.currentTarget?.dataset?.id;
    const progId = e.currentTarget?.dataset?.prog;
    const list = e.currentTarget?.dataset?.list;
    if (!gcId || !progId || !list) return;

    this.groupClasses = (this.groupClasses || []).map((gc) => {
      if (gc.id !== gcId) return gc;
      if (gc.readOnly) return gc;

      const next = { ...gc };
      if (list === 'available') {
        const s = new Set(next.pickedAvailable || []);
        s.has(progId) ? s.delete(progId) : s.add(progId);
        next.pickedAvailable = Array.from(s);
      } else {
        const s = new Set(next.pickedSelected || []);
        s.has(progId) ? s.delete(progId) : s.add(progId);
        next.pickedSelected = Array.from(s);
      }
      return next;
    });
  };

  addSelectedPrograms = (e) => {
    const gcId = e.currentTarget?.dataset?.id;
    if (!gcId) return;

    this.groupClasses = (this.groupClasses || []).map((gc) => {
      if (gc.id !== gcId) return gc;
      if (gc.readOnly) return gc;

      const picked = new Set(gc.pickedAvailable || []);
      if (picked.size === 0) return gc;

      const available = gc.availablePrograms || [];
      const selected = gc.selectedPrograms || [];

      const toMove = available.filter((p) => picked.has(p.id));
      const remainingAvailable = available.filter((p) => !picked.has(p.id));

      const selectedIds = new Set(selected.map((p) => p.id));
      const mergedSelected = [...selected, ...toMove.filter((p) => !selectedIds.has(p.id))];

      return {
        ...gc,
        availablePrograms: remainingAvailable,
        selectedPrograms: mergedSelected,
        pickedAvailable: []
      };
    });
  };

  removeSelectedProgram = (e) => {
    const gcId = e.currentTarget?.dataset?.id;
    const progId = e.currentTarget?.dataset?.prog;
    if (!gcId || !progId) return;

    this.groupClasses = (this.groupClasses || []).map((gc) => {
      if (gc.id !== gcId) return gc;
      if (gc.readOnly) return gc;

      const selected = gc.selectedPrograms || [];
      const available = gc.availablePrograms || [];

      const removed = selected.find((p) => p.id === progId);
      const remainingSelected = selected.filter((p) => p.id !== progId);

      return {
        ...gc,
        selectedPrograms: remainingSelected,
        availablePrograms: removed ? [...available, removed] : available
      };
    });
  };

  removePickedSelectedPrograms = (e) => {
    const gcId = e.currentTarget?.dataset?.id;
    if (!gcId) return;

    this.groupClasses = (this.groupClasses || []).map((gc) => {
      if (gc.id !== gcId) return gc;
      if (gc.readOnly) return gc;

      const picked = new Set(gc.pickedSelected || []);
      if (picked.size === 0) return gc;

      const selected = gc.selectedPrograms || [];
      const available = gc.availablePrograms || [];

      const toMove = selected.filter((p) => picked.has(p.id));
      const remainingSelected = selected.filter((p) => !picked.has(p.id));

      return {
        ...gc,
        selectedPrograms: remainingSelected,
        availablePrograms: [...available, ...toMove],
        pickedSelected: []
      };
    });
  };

  buildSubtitle(employeeType, employeeDivision) {
    const t = employeeType && employeeType !== 'None' ? employeeType : null;
    const d = employeeDivision && employeeDivision !== 'None' ? employeeDivision : null;
    if (t && d) return `${t} - ${d}`;
    if (t) return `${t}`;
    if (d) return `${d}`;
    return 'General';
  }

  normalizeError(e) {
    return e?.body?.message || e?.message || 'Unknown error';
  }

  toastError(message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Error',
        message,
        variant: 'error'
      })
    );
  }
}