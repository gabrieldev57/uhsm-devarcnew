import OmniscriptStepChart from "vlocity_ins/omniscriptStepChart";
import tmpl from "./aRC_StepChartWithoutClick.html";
import tmpl_nds from "./ndshtml.html";

export default class aRC_StepWithoutChartClick extends OmniscriptStepChart {

  connectedCallback() {
    super.connectedCallback();
  }

  render() {
    if (this.theme === 'nds') {
      return tmpl_nds;
    }
    return tmpl;
  }

  get customChildren(){
    return this.jsonDef.children.filter(step => {
      const isStep = step.isStep || step.type === 'Step' || false;
      return isStep && step.bShow !== false;
    });
  }

}