import omniscriptEditBlock from "vlocity_ins/omniscriptEditBlock";
import template from "./arc_EditBlockOverrideEditButton.html";
export default class arc_EditBlockOverrideEditButton extends omniscriptEditBlock{
    // your properties and methods here
    
    render()
    {
        if (this.jsonDef) {
            this._hasChildren = this.jsonDef.children.length > 0;
            this._isFirstIndex = this.jsonDef.index === 0;

            if (this._isCards && this._isFirstIndex) {
                // hides the first short card with no children
                if (!this._hasChildren) {
                    this.classList.add(this._theme + '-hide');
                } else {
                    this.classList.remove(this._theme + '-hide');
                }
            }
        }
        return template;
    }
}