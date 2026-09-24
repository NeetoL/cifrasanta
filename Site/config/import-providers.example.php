<?php
// Copie para import-providers.php. Configure somente fontes com autorização de importação.
// Seletores são XPath 1.0, executados apenas no DOM recebido, nunca como código.
return [
 'meu-site'=>[
  'enabled'=>false,
  'name'=>'Meu site autorizado',
  'authorization'=>'', // Referência da autorização/licença ou declaração de propriedade.
  'domains'=>['musicas.example.org'], // Hosts exatos, sem curingas. Inclua destinos de redirects permitidos.
  'selectors'=>[
   'titulo'=>'//h1[@id="titulo"]',
   'artista'=>'//*[@id="artista"]',
   'tom'=>'//*[@id="tom"]',
   'conteudo'=>'//pre[@id="cifra"]',
   'afinacao'=>'//*[@id="afinacao"]',
   'capotraste'=>'//*[@id="capotraste"]',
  ],
  'remove'=>['.//*[@class="anuncio"]'],
  'strip_prefixes'=>['tom'=>['Tom:'],'afinacao'=>['Afinação:'],'capotraste'=>['Capotraste:']],
  // 'section_selector'=>'.//h3', // Opcional: cabeçalhos curtos viram [Seção].
  'block_tags'=>['div','p','section','h2','h3'],
  'format'=>'aligned', // aligned: acordes sobre a letra; inline: formato [C]palavra.
 ],
];
