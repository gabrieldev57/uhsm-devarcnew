import { LightningElement, api, track } from 'lwc';

import ARC_OSResources from '@salesforce/resourceUrl/ARC_OSResources';


export default class HorizontalScrollWrapper extends LightningElement {
	@track isOverflowing = false;
	@track isLeftDisabled = true;
	@track isRightDisabled = true;

	iconChevron = ARC_OSResources + '/icon-chevron.svg#svg';

	// Bound function references for event listeners
	_resizeHandler;

	connectedCallback() {
		this._resizeHandler = this.checkOverflow.bind(this);
		window.addEventListener('resize', this._resizeHandler);
		window.addEventListener('orientationchange', this._resizeHandler);

		// Poll for changes every 300ms
		this.resizeInterval = setInterval(() => {
			this.checkOverflow();
		}, 300);
	}
	renderedCallback() {
		this.checkOverflow();
	}

	disconnectedCallback() {
		window.removeEventListener('resize', this._resizeHandler);
		window.removeEventListener('orientationchange', this._resizeHandler);
		if (this.resizeObserver) {
			this.resizeObserver.disconnect();
			this.resizeObserver = null;
		}
	}

	// Public API method to re-check overflow (can be called from parent)
	@api recheckOverflow() {
		this.checkOverflow();
	}

	// Public API method to scroll and center on a given element inside the slot
	@api scrollToElement(element) {
		// Allow passing a selector string or an element reference
		let target = element;
		if (typeof element === 'string') {
			target = this.template.querySelector(element);
		}
		if (!target) return;
		// Calculate target's center relative to container
		const targetCenter = target.offsetLeft + target.offsetWidth / 2;
		const scrollTo = targetCenter - this.refs.scrollContainer.clientWidth / 2;
		// Clamp to valid scroll range
		this.refs.scrollContainer.scrollLeft = Math.max(0, Math.min(this.refs.scrollContainer.scrollWidth - this.refs.scrollContainer.clientWidth, scrollTo));
		// Update arrow disabled state
		this.updateArrows();
	}

	// Scroll left by container width (on left arrow click)
	handleLeftClick() {
		const newPos = this.refs.scrollContainer.scrollLeft - this.refs.scrollContainer.clientWidth;
		this.refs.scrollContainer.scrollLeft = Math.max(0, newPos);
		this.updateArrows();
	}

	// Scroll right by container width (on right arrow click)
	handleRightClick() {
		const newPos = this.refs.scrollContainer.scrollLeft + this.refs.scrollContainer.clientWidth;
		this.refs.scrollContainer.scrollLeft = Math.min(this.refs.scrollContainer.scrollWidth - this.refs.scrollContainer.clientWidth, newPos);
		this.updateArrows();
	}

	// Update arrow disabled states based on current scroll position
	handleScroll() {
		this.updateArrows();
	}

	// Check if content overflows and update flags
	checkOverflow() {
		if (!this.refs?.scrollContainer) return;
		// Detect horizontal overflow
		if (this.refs.scrollContainer.scrollWidth > this.refs.scrollContainer.clientWidth) {
			this.isOverflowing = true;
			this.updateArrows();
		} else {
			// No overflow: hide arrows and reset positions
			this.isOverflowing = false;
			this.isLeftDisabled = true;
			this.isRightDisabled = true;
		}
	}

	// Helper to set isLeftDisabled/isRightDisabled based on scroll
	updateArrows() {
		if (!this.refs.scrollContainer) return;

		const scrollLeft = this.refs.scrollContainer.scrollLeft;
		const scrollRight = this.refs.scrollContainer.scrollWidth - this.refs.scrollContainer.clientWidth - scrollLeft;

		const epsilon = 1;
		this.isLeftDisabled = scrollLeft <= epsilon;
		this.isRightDisabled = scrollRight <= epsilon;

		// Update mask fade depending on scroll position
		this.refs.scrollContainer.style.setProperty('--mask-left', scrollLeft <= epsilon ? 'black' : 'transparent');
		this.refs.scrollContainer.style.setProperty('--mask-right', scrollRight <= epsilon ? 'black' : 'transparent');
	}
}