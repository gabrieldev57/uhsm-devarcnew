import { api, track, wire } from 'lwc';
import SimpleDrawer from 'c/aRC_SideDrawer';


export default class SimpleDrawerNavigationExample extends SimpleDrawer {
    // Add custom class for CSS
    @api customClass = "sl-navigation-drawer"

    @api menuItems;
    @api currentPageReference;

    handleSubmit() {
        this.close({});
    }
}