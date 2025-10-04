const images = document.querySelectorAll('img');

const fitSizeClass = 'image-in-lb-fit-size';
const zoomedSizeClass = 'image-in-lb-zoomed-size';

const lightboxWrapper = document.createElement('div');
lightboxWrapper.setAttribute('id', 'image-lightbox-wrapper');

document.body.appendChild(lightboxWrapper);

const lightboxCloseButton = document.createElement('div');
lightboxCloseButton.innerHTML = '×';
lightboxCloseButton.setAttribute('id', 'image-lightbox-close-btn');
lightboxCloseButton.setAttribute('title', 'Close the image lightbox');
lightboxCloseButton.addEventListener('click', function() {
    closeLightbox();
});

const lightboxKillingFloor = document.createElement('div');
lightboxKillingFloor.setAttribute('id', 'lightbox-killing-floor');
lightboxKillingFloor.addEventListener('click', function() {
    closeLightbox();
});

lightboxWrapper.appendChild(lightboxKillingFloor);

const lightbox = document.createElement('div');
lightbox.setAttribute('id', 'image-lightbox');
lightbox.appendChild(lightboxCloseButton);

lightboxWrapper.appendChild(lightbox);

function openLightbox(image) {
    document.getElementById('image-lightbox-wrapper').style.display = 'block';
    lightboxKillingFloor.style.display = 'block';

    image.classList.remove('image-in-content');
    image.classList.add('image-in-lightbox');
    image.classList.add('image-in-lb-fit-size');

    const lightboxChildren = lightbox.childNodes;
    lightboxChildren.forEach(child => {
        if (child.nodeName == 'IMG') {
            lightbox.removeChild(child);
        }
    });

    if (image.src.includes('.svg')) {
        lightboxWidth = '90vw';
        image.style.width = '90vw';
    }
    else {
        lightboxWidth = image.width + 'px';
    }
    document.getElementById('image-lightbox').appendChild(image);
    document.getElementById('image-lightbox').style.display = 'block';
    document.body.style.overflow = 'hidden';
    lightbox.style.width = image.clientWidth + 'px';
    lightbox.style.height = image.clientHeight + 'px';

    // Determine whether to allow zoom&pan - if the lightbox is of the same size as the image 100% size, then do not allow zoom&pan
    if ((image.clientWidth < image.naturalWidth) || (image.clientHeight < image.naturalHeight)) {
        image.setAttribute('title', 'Double-click to toggle zoom');
        image.style.cursor = 'zoom-in';
        image.ondblclick = function() {
            zoomImageInLightbox(image);
        }
        image.ontouchend = function(event) {
            handleDoubleTap(event);
        }
    }
    else {
        console.log("Zooming not possible, image too small.");
    }

    // Improved double-tap/double-click handling
    let lastTapTime = 0;

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
    // image.addEventListener('dblclick', handleDoubleTap);
    // image.addEventListener('touchend', handleDoubleTap);
}

function closeLightbox() {
    let lightboxedImageToClose = document.getElementById('active-lightboxed-image');
    if (lightboxedImageToClose.classList.contains(zoomedSizeClass)) {
        removeImagePanning(lightboxedImageToClose);
    }
    lightboxedImageToClose.classList.remove(zoomedSizeClass);
    lightboxedImageToClose.classList.remove(fitSizeClass);
    lightboxedImageToClose.removeAttribute('style');
    lightboxedImageToClose.remove();

    document.getElementById('image-lightbox-wrapper').style.display = 'none';
    lightboxKillingFloor.style.display = 'none';

    document.body.style.overflow = 'auto';
    document.getElementById('image-lightbox').style.display = 'none';
    event.stopPropagation();
}

function zoomImageInLightbox(boxedImage) {
    boxedImage.classList.toggle(fitSizeClass);
    boxedImage.classList.toggle(zoomedSizeClass);

    if (boxedImage.classList.contains(zoomedSizeClass)) {
        setupImagePanning(boxedImage);
    } else {
        removeImagePanning(boxedImage);
        boxedImage.style.cursor = 'zoom-in';
    }
}

function setupImagePanning(image) {
    let isDragging = false;
    let startX, startY;
    let translateX = 0, translateY = 0;

    // Ensure initial translation is set up
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
        translateX = image.initialTranslation.x + deltaX;
        translateY = image.initialTranslation.y + deltaY;

        // Prevent panning the image beyond the visible lightbox borders
        lightboxWidth = image.parentNode.clientWidth;
        lightboxHeight = image.parentNode.clientHeight;
        if (translateX > (-lightboxWidth / 2)) {
            translateX = (-lightboxWidth / 2)
        }
        if (translateY > (-lightboxHeight / 2)) {
            translateY = (-lightboxHeight / 2)
        }
        if (translateX < (-image.width + (lightboxWidth / 2))) {
            translateX = (-image.width + (lightboxWidth / 2))
        }
        if (translateY < (-image.height + (lightboxHeight / 2))) {
            translateY = (-image.height + (lightboxHeight / 2))
        }

        // Apply translation
        image.style.transform = `translate(${translateX}px, ${translateY}px)`;

        // Update the initial translation to the new position
        image.initialTranslation.x = translateX;
        image.initialTranslation.y = translateY;

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

// Loop through each image
images.forEach(img => {
    // Create a new anchor element
    const link = document.createElement('a');

    // Remove the hardcoded width attribute which comes probably from the template and conflicts with the lightbox
    // (and, in general, seems unneeded).
    img.removeAttribute('width');

    // Optionally, add a title or alt text
    link.setAttribute('title', img.alt || '');
    link.setAttribute('class', 'image-in-content-link');

    // Create label for the image and fill it with the alt text
    const label = document.createElement('div');
    label.innerHTML = (img.alt || '');
    label.setAttribute('class', 'image-in-content-label');

    // Add class
    img.setAttribute('class', 'image-in-content');
    const imgInLB = img.cloneNode();
    imgInLB.setAttribute('id', 'active-lightboxed-image');
    img.addEventListener('click', function() {
        openLightbox(imgInLB);
    });

    // Replace the image with the anchor element
    img.parentNode.replaceChild(link, img);

    // Append the image inside the anchor
    link.appendChild(img);
    link.appendChild(label);
});