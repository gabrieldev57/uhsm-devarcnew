import { LightningElement } from "lwc";
import { loadStyle } from 'lightning/platformResourceLoader';
import sparkResources from '@salesforce/resourceUrl/Spark';

// import icons from "@salesforce/resourceUrl/Icons";

export default class aRC_MC_BaseComponent extends LightningElement {
	// phone = `${icons}/icon-phone.svg#svg`;
	// email = `${icons}/icon-email.svg#svg`;
	// location = `${icons}/icon-locationpin.svg#svg`;
	// check = `${icons}/icon-check.svg#svg`;
	// // Social media icons
	// Apple = `${icons}/social-apple.svg#svg`;
	// Behance = `${icons}/social-behance.svg#svg`;
	// Dribble = `${icons}/social-dribble.svg#svg`;
	// Dropbox = `${icons}/social-dropbox.svg#svg`;
	// Facebook = `${icons}/social-facebook.svg#svg`;
	// Instagram = `${icons}/social-instagram.svg#svg`;
	// LinkedIn = `${icons}/social-linkedin.svg#svg`;
	// Medium = `${icons}/social-medium.svg#svg`;
	// Messenger = `${icons}/social-messenger.svg#svg`;
	// Pinterest = `${icons}/social-pinterest.svg#svg`;
	// QQ = `${icons}/social-qq.svg#svg`;
	// Reddit = `${icons}/social-reddit.svg#svg`;
	// Skype = `${icons}/social-skype.svg#svg`;
	// Slack = `${icons}/social-slack.svg#svg`;
	// Snapchat = `${icons}/social-snapchat.svg#svg`;
	// Spotify = `${icons}/social-spotify.svg#svg`;
	// Telegram = `${icons}/social-telegram.svg#svg`;
	// TikTok = `${icons}/social-tiktok.svg#svg`;
	// Tumblr = `${icons}/social-tumblr.svg#svg`;
	// Twitter = `${icons}/social-twitter.svg#svg`;
	// Vimeo = `${icons}/social-vimeo.svg#svg`;
	// VK = `${icons}/social-vk.svg#svg`;
	// WeChat = `${icons}/social-wechat.svg#svg`;
	// Whatsapp = `${icons}/social-whatsapp.svg#svg`;
	// Youtube = `${icons}/social-youtube.svg#svg`;
	check = `${sparkResources}/Icons/icon-check.svg#svg`;
	
	//////////////////////////////////////////////////////////////////
	////////////////////    CONNECTED CALLBACK    ////////////////////
	//////////////////////////////////////////////////////////////////
	// Loads the lwc.css stylesheet for components
	connectedCallback() {
		loadStyle(this, sparkResources + '/lwc.css');

        this.items = this[this.section];
	}

	renderedCallback(){
		if (this.items && this.items.length > 0) {
			let component = this.template.querySelector('.spk-lwc');
			let elems = this.template.querySelectorAll('.wbench-select');
			let imageElements = this.template.querySelectorAll(`.spk-image,.spk-bg-image`);
			
			this.items.forEach((item, index) => {
				// Check if image is video
				if(item.image){
					switch (item.cvExt) {
						case 'm4v':
							case 'avi':
								case 'mpg':
									case 'mp4':
										item.isVideo = true;
										item.videoType = "video/"+item.cvExt.toLowerCase();
										break;
										default:
							item.isVideo = false;
							break;
						}
					}
					
					if(item.setup && !this.setupInitialized){
						let setup = JSON.parse(item.setup);
						this.setupInitialized = true;
						// Add full width class
						if(setup.fullWidth){
							if(elems[index]) elems[index].classList.add("spk-fullwidth")
						}else{
							if(elems[index]) elems[index].classList.remove("spk-fullwidth")
						}
						// Automatically set component animation
						if(setup.componentAnimation || setup.animateInstantly){
							this.setCompAnimation(component, setup.componentAnimation, setup.animateInstantly);
							this.setAnimationDelay(component, setup.componentAnimationDelay);
						}
					}
					
					if(item.styles){
						let styles = JSON.parse(item.styles);
						// Automatically set image size
						if(styles.imageSize){
							if(imageElements[index]) this.setImageSize(imageElements[index], styles.imageSize); 
						}
						// Automatically set image focus
						if(styles.imageFocusX !== undefined || styles.imageFocusY !== undefined){
							if(imageElements[index]) this.setImageFocus(imageElements[index], styles.imageFocusX, styles.imageFocusY); 
						}
						if(styles.animation){
							this.setAnimation(elems[index], styles.animation);
							this.setAnimationDelay(elems[index], styles.animationDelay);
						}
						// Automatically set button colors
						if(styles.buttonColor || styles.buttonBackgroundColor || styles.buttonHoverColor || styles.buttonActiveColor){
							if(component) {
								this.setButtonColors(index, styles);
							}
						}
					}
				})
				
				// let risingNumbers = this.template.querySelectorAll('.spk-risingnumber');
				// if(risingNumbers.length > 0){
					// 	console.log("RISING NUMBER FOUND")
					// 	risingNumbers.forEach(number => {
			// 		try {
				// 			console.log("COUNTING")
				// 			number.countTo();
				// 		} catch (error) {
					// 			console.log(error);
					// 		}
					// 	})
					// }
				}
			}
			
			//////////////////////////////////////////////////////////////////
			///////////////////////   IMAGE SIZE  ////////////////////////////
			//////////////////////////////////////////////////////////////////
			setImageSize(el, imageSize){
				if(!imageSize || imageSize === 100) el.style.backgroundSize = "cover";
				else el.style.backgroundSize = imageSize+"%";
			}
			
			//////////////////////////////////////////////////////////////////
			///////////////////////   IMAGE FOCUS  ///////////////////////////
	//////////////////////////////////////////////////////////////////
	setImageFocus(el, focusX, focusY){
		el.style.backgroundPosition = `${focusX !== undefined ? focusX : 50}% ${focusY !== undefined ? focusY : 50}%`;
		el.style.objectPosition = `${focusX !== undefined ? focusX : 50}% ${focusY !== undefined ? focusY : 50}%`;
	}

	//////////////////////////////////////////////////////////////////
	/////////////////////   BUTTON COLORS  ///////////////////////////
	//////////////////////////////////////////////////////////////////
	setButtonColors(index, styles){
		let buttons = this.template.querySelectorAll(`[data-index="${index}"] .spk-button`);
		buttons.forEach(button => {
			if(styles.buttonOutlineColor) button.style.setProperty('--color-text', styles.buttonOutlineColor);
			if(styles.buttonBackgroundColor) button.style.setProperty('--button-bg-color', styles.buttonBackgroundColor);
			if(styles.buttonHoverColor) {
				button.style.setProperty('--button-bg-color-hover', styles.buttonHoverColor);
				button.style.setProperty('--button-bg-color-focus', styles.buttonHoverColor);
			}
			if(styles.buttonActiveColor) button.style.setProperty('--button-bg-color-active', styles.buttonActiveColor);
		});
	}

	//////////////////////////////////////////////////////////////////
	///////////////////////   ANIMATIONS  ////////////////////////////
	//////////////////////////////////////////////////////////////////
	setAnimationEvents(el){
		this.listener = () => this.checkComponentInViewport(el);
		if (window.addEventListener) {
			addEventListener('scroll', this.listener, false);
			addEventListener('resize', this.listener, false);
		} else if (window.attachEvent) {
			attachEvent('onscroll', this.listener);
			attachEvent('onresize', this.listener);
		}
	}	
	destroyAnimationEvents(){
		if (window.removeEventListener) {
			removeEventListener('scroll', this.listener, false);
			removeEventListener('resize', this.listener, false);
		} else if (window.detachEvent) {
			detachEvent('onscroll', this.listener);
			detachEvent('onresize', this.listener);
		}
	}
	checkComponentInViewport(el){
		if(this.inViewport(el)){
			el.classList.add("spk-anim-in");
			this.destroyAnimationEvents(el);
		}
	}
	inViewport(el){
		let rect = el.getBoundingClientRect();
		const matrix = getComputedStyle(el, null).transform.match(/\d+/g) || [];
		return (
			// rect.top + Number(matrix[5] || 0) >= 0 &&
			// rect.bottom + Number(matrix[5] || 0) <= window.innerHeight
			rect.top + Number(matrix[5] || 0) + 300 <= window.innerHeight
		);
	}
	
	setCompAnimation(el, anim, instantly){
		this.setCompParentAnimation(instantly);
		this.setAnimation(el, anim);
	}

	setCompParentAnimation(instantly){
		this.animationEventsAdded = true;
		let comp = this.template.querySelector(".spk-lwc");
		comp.classList.add("spk-anim-parent");
		// Start event listener for component in viewport
		if(!this.workbenchlwc && !instantly) {
			this.setAnimationEvents(comp);
		}
		else {
			// if (window.addEventListener) {
			// 	addEventListener('DOMContentLoaded', () => {
					comp.classList.add("spk-anim-in");
			// 	}, false);
			// 	addEventListener('load', () => {
			// 		comp.classList.add("spk-anim-in");
			// 	}, false);
			// } else if (window.attachEvent) {
			// 	attachEvent('onDOMContentLoaded', () => {
			// 		comp.classList.add("spk-anim-in");
			// 	});
			// 	attachEvent('onload', () => {
			// 		comp.classList.add("spk-anim-in");
			// 	});
			// }
		}
	}

	setAnimation(el, anim) {
		if(!this.animationEventsAdded) this.setCompParentAnimation();
		switch (anim) {
			case "fade":
				el.classList.add("spk-anim-fade");
				break;
			case "fadetop":
				el.classList.add("spk-anim-fadefromtop");
				break;
			case "fadebottom":
				el.classList.add("spk-anim-fadefrombottom");
				break;
			case "fadeleft":
				el.classList.add("spk-anim-fadefromleft");
				break;
			case "faderight":
				el.classList.add("spk-anim-fadefromright");
				break;
			case "fadescale":
				el.classList.add("spk-anim-fadescale");
				break;
			case "fadescaletop":
				el.classList.add("spk-anim-fadescalefromtop");
				break;
			case "fadescalebottom":
				el.classList.add("spk-anim-fadescalefrombottom");
				break;
			case "fadescaleleft":
				el.classList.add("spk-anim-fadescalefromleft");
				break;
			case "fadescaleright":
				el.classList.add("spk-anim-fadescalefromright");
				break;
			case "slideleft":
				el.classList.add("spk-anim-slidefromleft");
				break;
			case "slideright":
				el.classList.add("spk-anim-slidefromright");
				break;
			default:
				break;
		}
	}

	setAnimationDelay(el, delay) {
		switch (delay) {
			case ".5":
				el.classList.add("spk-anim-d-p5");
				break;
			case "1":
				el.classList.add("spk-anim-d-1");
				break;
			case "1.5":
				el.classList.add("spk-anim-d-1p5");
				break;
			case "2":
				el.classList.add("spk-anim-d-2");
				break;
			case "2.5":
				el.classList.add("spk-anim-d-2p5");
				break;
			case "3":
				el.classList.add("spk-anim-d-3");
				break;
			case "3.5":
				el.classList.add("spk-anim-d-3p5");
				break;
			case "4":
				el.classList.add("spk-anim-d-4");
				break;
			default:
				break;
		}
	}
}