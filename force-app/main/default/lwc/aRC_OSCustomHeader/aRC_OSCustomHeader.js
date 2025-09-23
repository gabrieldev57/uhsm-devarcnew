import OmniscriptStepChart from "vlocity_ins/omniscriptStepChart";
import tmpl from "./aRC_OSCustomHeader.html";

// import OSResources from '@salesforce/resourceUrl/ARC_OSResources'


export default class aRC_OSCustomHeader extends OmniscriptStepChart {

	render() {
		console.log('hello');
		return tmpl;
	}

}