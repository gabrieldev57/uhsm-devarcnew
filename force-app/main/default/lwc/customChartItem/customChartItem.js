import OmniscriptStepChartItems from "vlocity_ins/omniscriptStepChartItems";
import tmpl_vertical from "./customChartItem.html";
import tmpl_horizontal from "./customChartItem_horizontal.html";
import tmpl_nds from "./customChartItem_nds.html";
import pubsub from 'vlocity_ins/pubsub';

export default class CustomChartItem extends OmniscriptStepChartItems {

  _hasDisabled = false;
  
  connectedCallback() {
    super.connectedCallback();
    pubsub.register('omniscript_action', {
        data: this.handleOmniStepLoadData.bind(this),
    });
  }

  renderedCallback() {
    if (this.scriptHeaderDef && this.scriptHeaderDef.asIndex) {
      this.currentStepIndex = this.scriptHeaderDef.asIndex;
      this.applyLightningStyles();

      if (this.jsonDef.bShow === false) {
        this.dispatchEvent(
          new CustomEvent("omniaddclasslist", {
            bubbles: true,
            composed: true,
            detail: {
              index: this.currentStepIndex,
              className: this.theme + "-hide"
            }
          })
        );
      } else {
        this.dispatchEvent(
          new CustomEvent("omniremoveclasslist", {
            bubbles: true,
            composed: true,
            detail: {
              index: this.currentStepIndex,
              className: this.theme + "-hide"
            }
          })
        );
      }
    }
  }

// commented by RG : 5/28/2022
//   get isdisabled() {
//     if(this.jsonData && this.jsonData.disablestepindex){
//       return this.currentIndex > this.jsonData.disablestepindex;
//     }
//     return false;
//   }



handleOmniStepLoadData(data) {
    // switch(data.name) {
    //     case 'SummaryStep': // for group summary screen
    //         this.handleOmniSummaryStepLoadData(data);
    //         break;
    //     case 'Step_Summary': // SummaryScreenForCancelMember, SummaryScreenEnrollEmployee,ReinstateSummary    
    //         this.handleOmniSummaryStepLoadData(data);
    //         break;
    //     case 'Summary': // SummaryScreenMemberLevelChanges    
    //         this.handleOmniSummaryStepLoadData(data);
    //         break;
    //     default:
    //     }
    if(data && data.name && data.name === 'DisableSteps' && !this._hasDisabled){
      this._hasDisabled = true;
       this.handleOmniSummaryStepLoadData(data);
    }
  }


handleOmniSummaryStepLoadData(data) {
// console.log('>>>>data is >>>>',JSON.stringify(data));
  this.isdisabled = true;
}

  render() {
    if (this.theme === 'nds') {
      return tmpl_nds;
    }
    return this.isVertical ? tmpl_vertical : tmpl_horizontal;
  }

}