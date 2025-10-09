// Add document-wide event listener to close the lightbox on <Escape> key press
document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
      // Fire closeLightbox() only if the fence element has a child (the image).
      // If it does not, there is nothing to close.
      if (document.getElementById('lightbox-fence').firstChild) {
          closeLightbox();
      }
  }
});

// Set up the current zoom scale variable globally because it is needed across multiple functions,
// some of which are called via event listener callbacks, making it more painful to pass values across them all.
let currentZoomScale = 0;

// Enumerate all images in the page
const images = document.querySelectorAll('img');

// Classes for unzoomed (fit size) and zoomed image (zooming by double click in the lightbox)
const fitSizeClass = 'image-in-lb-fit-size';
const zoomedSizeClass = 'image-in-lb-zoomed-size';

// Create persistent DOM elements for the lightbox - used for any image in the page
// The image label
const labelEl = document.createElement('p');
labelEl.setAttribute('class', 'image-in-content-label');

// The wrapper covering the whole viewport and blurring the background of displayed lightbox
const lightboxWrapper = document.createElement('div');
lightboxWrapper.setAttribute('id', 'image-lightbox-wrapper');

// Element to show hint about zoom on scroll. Only shown on first lightbox open until page reload
const zoomHelperTip = document.createElement('div');
zoomHelperTip.setAttribute('id', 'lightbox-zoom-helper-tip');
zoomHelperTip.innerHTML = 'Zoom to scroll';
// Remove the zoom helper from the DOM if user clicks it (i.e., wants to get rid of it)
zoomHelperTip.addEventListener('click', function() {
    zoomHelperTip.remove();
});

let zoomHelperDisplayedAlready = false;

document.body.appendChild(lightboxWrapper);

// The lightbox closing button
const lightboxCloseButton = document.createElement('div');
lightboxCloseButton.innerHTML = '×';
lightboxCloseButton.setAttribute('id', 'image-lightbox-close-btn');
lightboxCloseButton.setAttribute('title', 'Close the image lightbox');
lightboxCloseButton.setAttribute('alt', 'Close the image lightbox');
lightboxCloseButton.addEventListener('click', function() {
    closeLightbox();
});

const lightboxZoomInButton = document.createElement('div');
lightboxZoomInButton.setAttribute('id', 'zoom-in-btn');
lightboxZoomInButton.innerHTML = '+';
lightboxZoomInButton.setAttribute('title', 'Zoom in');
lightboxZoomInButton.setAttribute('alt', 'Zoom in');

const lightboxZoomOutButton = document.createElement('div');
lightboxZoomOutButton.setAttribute('id', 'zoom-out-btn');
lightboxZoomOutButton.innerHTML = '−';
lightboxZoomOutButton.setAttribute('title', 'Zoom out');
lightboxZoomOutButton.setAttribute('alt', 'Zoom out');

const lightboxZoomResetButton = document.createElement('div');
lightboxZoomResetButton.setAttribute('id', 'zoom-reset-btn');
lightboxZoomResetButton.innerHTML = '•';
lightboxZoomResetButton.setAttribute('title', 'Reset zoom');
lightboxZoomResetButton.setAttribute('alt', 'Reset zoom');

// Element in the wrapper but beneath the lightbox element to enable closing the lightbox when user clicks the blurred lightbox background
const lightboxKillingFloor = document.createElement('div');
lightboxKillingFloor.setAttribute('id', 'lightbox-killing-floor');
lightboxKillingFloor.addEventListener('click', function() {
    closeLightbox();
});

lightboxWrapper.appendChild(lightboxKillingFloor);

// The lightbox
const lightbox = document.createElement('div');
lightbox.setAttribute('id', 'image-lightbox');
lightbox.appendChild(lightboxCloseButton);
lightbox.appendChild(lightboxZoomInButton);
lightbox.appendChild(lightboxZoomOutButton);
lightbox.appendChild(lightboxZoomResetButton);

// Separate bounding box for the lightbox inside the lightbox element
// It has to be separate to
// - prevent zoomed image from overflowing the lightbox
// - but enable closing button and label be beyond the bounding box of the displayed image
const lightboxFence = document.createElement('div');
lightboxFence.setAttribute('id', 'lightbox-fence');

lightbox.appendChild(lightboxFence);

lightboxWrapper.appendChild(lightbox);
lightboxWrapper.appendChild(zoomHelperTip);

// Function to open the lightbox, set required properties and call functions
function openLightbox(image, imageLabel) {
    // TODO: some element selections could be improved by using the variables holding the elements instead of using getElementById or …byClass.
    document.getElementById('image-lightbox-wrapper').style.display = 'block';
    lightboxKillingFloor.style.display = 'block';

    // If the zoom helper has not been shown yet, let it show for N miliseconds
    // and then give it a disappearing transition, and, after N+(transition time) miliseconds,
    // remove it from the DOM.
    if (!zoomHelperDisplayedAlready) {
        setTimeout(function() {
            zoomHelperTip.style.animation = 'fadeOut 700ms ease-out forwards';
        }, 5000);
        setTimeout(function() {
            zoomHelperTip.remove();
        }, 5700);
        zoomHelperDisplayedAlready = true;
    }

    // Switch classes from in-article image to in-lightbox image
    image.classList.remove('image-in-content');
    image.classList.add('image-in-lightbox');
    image.classList.add('image-in-lb-fit-size');

    // Remove image and label (<p>) elements from the lightbox element
    // (this is used when user opens one image, closes it, and opens the lightbox again, possibly with another image in the page - the child elements need to be replaced)
    const lightboxChildren = lightbox.childNodes;
    lightboxChildren.forEach(child => {
        if (child.nodeName == 'IMG' || child.nodeName == 'P') {
            lightbox.removeChild(child);
        }
    });

    // Create label for the image and fill it with the text found in the next sibling element; see the calling statement for details
    labelEl.innerHTML = (imageLabel);

    // Set size of the displayed image
    // I seem to have lost my train of thought and don't use the widths from herein. TODO - this should be refactored to avoid unneeded calculations
    // If the image is SVG, we cannot depend on the "natural" width
    // because that is an arbitrary value set by browsers and, at least in FF, it is too small -> set it to 90vw instead
    // The lightbox has max-width and max-height of 90vw in case the image is bigger than user's viewport
    if (image.src.includes('.svg')) {
        lightboxWidth = '90vw';
        image.style.width = '90vw';
    }
    else {
        lightboxWidth = image.width + 'px';
    }
    document.getElementById('lightbox-fence').appendChild(image);

    // Append image label to the lightbox (grand-parent of the image, parent is the fence)
    if (imageLabel) {
        image.parentNode.parentNode.appendChild(labelEl);
    }

    // Display the lightbox by setting it to block and prevent the body to show scrollbars when lightbox open
    document.getElementById('image-lightbox').style.display = 'block';
    document.body.style.overflow = 'hidden';

    // Set size of the displayed lightbox and the fence
    lightbox.style.width = image.clientWidth + 'px';
    lightbox.style.height = image.clientHeight + 'px';

    lightboxFence.style.width = image.clientWidth + 'px';
    lightboxFence.style.height = image.clientHeight + 'px';

    // Make sure the label is not higher than the ( viewport height minus image height ) divided by two
    // The magical value of 50 is uncomfortable but needed.
    // The solution is very suboptimal - TODO - it would be better to move the image higher and if that would not be enough, make it smaller.
    labelEl.style.maxHeight = (window.innerHeight - image.clientHeight - 30) / 2 + 'px';

    // Determine whether to allow zoom&pan - if the lightbox is of the same size as the image 100% size, then do not allow zoom&pan
    // If zoom allowed, cal zoom function on double-click and double-touch
    // Temporarily commented out to allow zoom by scroll on smaller images.
    // TODO: It would be preferable to enlarge and shrink the lightbox when zooming small images
    // if ((image.clientWidth < image.naturalWidth) || (image.clientHeight < image.naturalHeight)) {
        image.setAttribute('title', 'Scroll to zoom');
        // image.style.cursor = 'zoom-in';
        let initialZoomScale = 1;
        currentZoomScale = initialZoomScale;

        lightboxZoomInButton.onclick = function() {
            manualZoom(image, initialZoomScale, 'plus');
        };

        lightboxZoomOutButton.onclick = function() {
            manualZoom(image, initialZoomScale, 'minus');
        };

        lightboxZoomResetButton.onclick = function() {
            manualZoom(image, initialZoomScale, 'reset');
        };

        image.addEventListener("wheel", function() {
           zoomImageByWheel(image, initialZoomScale);
        });
    // }
    // else {
    // }

    // Improved double-tap/double-click handling
    let lastTapTime = 0;

    // Count tapping is a double-tap if they occur less than 300ms apart
    function handleDoubleTap(e) {
        const currentTime = new Date().getTime();
        const tapLength = currentTime - lastTapTime;

        if (tapLength < 300 && tapLength > 0) {
            // Prevent default to stop potential zooming or other default behaviors
            e.preventDefault();
            zoomImageInLightbox(image);
        }

        lastTapTime = currentTime;
    }

    // Add both mouse and touch event listeners
    // Note: Adding event listeners does not work as the events do not get fired if the lightbox is closed and opened again
    // That is why we are using the ondblclick() abd ontouchend()
    // image.addEventListener('dblclick', handleDoubleTap);
    // image.addEventListener('touchend', handleDoubleTap);
}

// Handle events when lightbox is closed - hide the lightbox, wrapper, image, remove zoomed classes
function closeLightbox() {
    let lightboxedImageToClose = document.getElementById('active-lightboxed-image');
    if (lightboxedImageToClose.classList.contains(zoomedSizeClass)) {
        removeImagePanning(lightboxedImageToClose);
    }
    document.getElementById('image-lightbox-wrapper').style.animation = 'fadeOut 0.5s ease-out forwards';
    setTimeout(function() {
        lightboxedImageToClose.classList.remove(zoomedSizeClass);
        lightboxedImageToClose.classList.remove(fitSizeClass);
        lightboxedImageToClose.removeAttribute('style');
        lightboxedImageToClose.remove();

        document.getElementById('image-lightbox-wrapper').style.animation = '';
        document.getElementById('image-lightbox-wrapper').style.display = 'none';
        lightboxKillingFloor.style.display = 'none';

        document.body.style.overflow = 'auto';
        document.getElementById('image-lightbox').style.display = 'none';
    }, 500);

    event.stopPropagation();
}

// Handle zooming the image if allowed and setup panning support on mousedown
// The image is zoomed to the center, the panning has to start there as well.
// The top-left corner also must not be moved beyond the top-left corner of the fence and similarly with the bottom-right corner.
function zoomImageInLightbox(boxedImage) {
    boxedImage.classList.toggle(fitSizeClass);
    boxedImage.classList.toggle(zoomedSizeClass);

    if (boxedImage.classList.contains(zoomedSizeClass)) {
        setupImagePanning(boxedImage);
    } else {
        removeImagePanning(boxedImage);
        // boxedImage.style.cursor = 'zoom-in';
    }
}

function zoomImageByWheel(image, initialZoomScale, zoomDirection = 0) {
    const zoomStep = 0.3;
    if (zoomDirection == 0) {
        zoomDirection = event.deltaY;
    }
    else if (zoomDirection == 2) {
        currentZoomScale = initialZoomScale;
    }


    if (zoomDirection != 2) {
        if ((zoomDirection < 0) && (currentZoomScale + zoomStep >= 4)) {
            currentZoomScale = 4;
        }
        else if ((zoomDirection < 0) && (currentZoomScale < 4)) {
            currentZoomScale += 0.3;
        }
        else if (currentZoomScale - zoomStep > initialZoomScale) {
            currentZoomScale -= 0.3;
        }
        else {
            currentZoomScale = initialZoomScale;
        }
    }

    if (currentZoomScale > 1) {
        // image.classList.remove(fitSizeClass);
        // image.classList.add(zoomedSizeClass);
        setupImagePanning(image);
    }
    else {
        removeImagePanning(image);
        // image.style.cursor = 'zoom-in';
    }
    image.style.transform = 'scale(' + currentZoomScale + ')';
}

function manualZoom(image, initialZoomScale, zoomDirection) {
    if (zoomDirection == 'plus') {
        zoomImageByWheel(image, initialZoomScale, -1)
    }
    else if (zoomDirection == 'minus') {
        zoomImageByWheel(image, initialZoomScale, 1)
    }
    else if (zoomDirection == 'reset') {
        zoomImageByWheel(image, initialZoomScale, 2)
    }
}

function setupImagePanning(image) {
    let isDragging = false;
    let startX, startY;
    let transformX = 0, transformY = 0;

    // Ensure initial translation is set up
    // Since the panning position is set in pixels, the initial panning position means recalculate the translation(50%, 50%) to pixels,
    // i.e., half the dimensions of the full-sized image
    if (!image.initialTranslation) {
        const rect = image.getBoundingClientRect();
        image.initialTranslation = {
            x: -rect.width / 2,
            y: -rect.height / 2
        };
    }

    function getEventCoordinates(e) {
        // Support both mouse and touch events
        return e.touches ? e.touches[0] : e;
    }

    function startDrag(e) {
        // Prevent default for both mouse and touch events
        e.preventDefault();

        // Only handle primary mouse button for mouse events
        if (e.type === 'mousedown' && e.button !== 0) return;

        // Do not allow panning if the image fits the lightbox (is not zoomed)
        if (currentZoomScale <= 1) {
            return;
        }
        isDragging = true;

        // Get coordinates
        const event = getEventCoordinates(e);

        // Record the initial position
        startX = event.clientX;
        startY = event.clientY;

        image.style.cursor = 'grabbing';
    }

    function drag(e) {
        if (!isDragging) return;

        // Prevent default scrolling during drag
        e.preventDefault();

        // Get coordinates
        const event = getEventCoordinates(e);

        // Calculate the difference in movement
        const deltaX = event.clientX - startX;
        const deltaY = event.clientY - startY;

        // Update total translation
        transformX = image.initialTranslation.x + deltaX;
        transformY = image.initialTranslation.y + deltaY;

        // Prevent panning the image beyond the visible lightbox borders
        // Note that the transformX and transformY values are negative
        // because they were used for translation in the past. 
        lightboxWidth = image.parentNode.clientWidth;
        lightboxHeight = image.parentNode.clientHeight;
        if (transformX >= 0) {
            transformX = 0;
        }
        if (transformY >= 0) {
            transformY = 0;
        }
        if (transformX <= -lightboxWidth) {
            transformX = -lightboxWidth;
        }
        if (transformY <= -lightboxHeight) {
            transformY = -lightboxHeight;
        }

        // Apply origin transformation
        image.style.transformOrigin = `${-transformX}px ${-transformY}px`;

        // Update the initial translation to the new position
        image.initialTranslation.x = transformX;
        image.initialTranslation.y = transformY;

        // Reset start position for next move
        startX = event.clientX;
        startY = event.clientY;
    }

    function stopDrag() {
        isDragging = false;
        image.style.cursor = 'grab';
    }

    // Set initial cursor style
    image.style.cursor = 'grab';

    // Add event listeners for both mouse and touch events
    const mouseEvents = [
        { type: 'mousedown', listener: startDrag, target: image },
        { type: 'touchstart', listener: startDrag, target: image },
        { type: 'mousemove', listener: drag, target: document },
        { type: 'touchmove', listener: drag, target: document },
        { type: 'mouseup', listener: stopDrag, target: document },
        { type: 'touchend', listener: stopDrag, target: document }
    ];

    // Store and add listeners
    image.panningListeners = mouseEvents.map(event => {
        event.target.addEventListener(event.type, event.listener, { passive: false });
        return event;
    });
}

// Remove control variables and event listeners used for panning
function removeImagePanning(image) {
    if (image.panningListeners) {
        // Remove all stored event listeners
        image.panningListeners.forEach(event => {
            event.target.removeEventListener(event.type, event.listener);
        });

        image.style.cursor = '';

        // Reset transform and remove stored translation
        image.style.transform = '';
        delete image.initialTranslation;
    }
}

// Loop through each image in the page
images.forEach(img => {
    // Create a new link element
    const link = document.createElement('a');

    // Remove the hardcoded width attribute which comes probably from the template and conflicts with the lightbox
    // (and, in general, is unneeded as we set responsive width for not-lightboxed in-content images).
    img.removeAttribute('width');

    // Optionally, add a title from the alt text
    link.setAttribute('title', img.alt || '');

    // New class for the lightboxable image links
    link.setAttribute('class', 'image-in-content-link');

    // Create image label
    // In our EvoDocs context, it is the content of the nextSibling element (which is the <p> right after the image);
    // this is very specific for our Documentation and the declaration here needs to change should the template change
    let imageLabel = '';
    if (img.parentNode.nextElementSibling) {
        imageLabel = img.parentNode.nextElementSibling.innerHTML;
    }

    // New class for the lightboxable images
    img.setAttribute('class', 'image-in-content');

    // Clone the image for the lightbox so that we can leave the properties of the original image as they were
    const imgInLB = img.cloneNode();
    imgInLB.setAttribute('id', 'active-lightboxed-image');

    // Open the lightbox on mouse click
    img.addEventListener('click', function() {
        openLightbox(imgInLB, imageLabel);
    });

    // Replace the image with the link element
    img.parentNode.replaceChild(link, img);

    // Append the image inside the link
    link.appendChild(img);
});
