/// Cache de packs adapté à la plateforme : fichiers sur mobile et bureau,
/// stockage du navigateur sur le web.
library;

export 'content_pack_cache_io.dart'
    if (dart.library.js_interop) 'content_pack_cache_web.dart'
    show createPlatformContentPackCache;
