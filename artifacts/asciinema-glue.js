
(function(){
  // Centralized glue: find any <asciinema-player src=...> element and try a
  // few robust strategies to ensure playback works even if the player bundle
  // did not auto-register the custom element.
  function isRegistered(){ try{ return !!(window.customElements && window.customElements.get('asciinema-player')); }catch(e){return false;} }
  function findFactoryGlobal(){
    var names=['AsciinemaPlayer','asciinemaPlayer','Asciinema','asciinema','AsciinemaPlayerJS'];
    for(var i=0;i<names.length;i++){ var f=window[names[i]]; if(f&&typeof f.create==='function') return f; }
    try{ for(var k in window){ var v=window[k]; if(v&&typeof v.create==='function') return v; } }catch(e){}
    return null;
  }
  async function tryEvalLocal(path){
    try{
      var resp = await fetch(path);
      if(!resp.ok) return null;
      var code = await resp.text();
      try{
        var factory = (0,eval)('('+code+')');
        if(factory && typeof factory.create==='function') return factory;
      }catch(e){
        try{ (0,eval)(code); }catch(e2){}
      }
    }catch(e){}
    return null;
  }
  async function instantiate(){
    if(isRegistered()) return;
    var el = document.querySelector("asciinema-player[src]");
    if(!el) return;
    var src = el.getAttribute('src') || '';
    try{
      var factory = findFactoryGlobal();
      if(factory){ try{ factory.create(src, el, {preload:true}); return; }catch(e){ console.error('asciinema: factory.create failed',e); } }
    }catch(e){}
    try{
      var factory2 = await tryEvalLocal('./asciinema-player.min.js');
      if(factory2 && typeof factory2.create==='function'){
        try{ factory2.create(src, el, {preload:true}); return; }catch(e){ console.error('asciinema: factory.create after eval failed', e); }
      }
    }catch(e){}
    try{ var s=document.createElement('script'); s.src='https://cdn.jsdelivr.net/npm/asciinema-player@3.11.1/dist/asciinema-player.min.js'; s.crossOrigin='anonymous'; s.async=true; document.head.appendChild(s); }catch(e){console.error('asciinema: failed to load CDN',e);} 
  }
  if(document.readyState==='loading'){ document.addEventListener('DOMContentLoaded',function(){ setTimeout(instantiate,200); }); setTimeout(instantiate,600); } else instantiate();
})();
