<div class="chord-diagram" aria-label="Acorde <?= e($name) ?>, desenho simplificado"><strong><?= e($name) ?></strong><svg viewBox="0 0 58 86" role="img" aria-hidden="true">
<?php for ($stringIndex=0; $stringIndex<6; $stringIndex++): $x=7+$stringIndex*8; ?><line x1="<?= $x ?>" y1="18" x2="<?= $x ?>" y2="73" /><?php endfor; ?>
<?php for ($fret=0; $fret<6; $fret++): $y=18+$fret*11; ?><line x1="7" y1="<?= $y ?>" x2="47" y2="<?= $y ?>" class="<?= $fret===0 ? 'nut' : '' ?>" /><?php endfor; ?>
<?php for ($stringIndex=0; $stringIndex<min(6,strlen($fingering)); $stringIndex++): $x=7+$stringIndex*8; $value=$fingering[$stringIndex]; ?>
<?php if ($value==='x'): ?><line x1="<?= $x-2 ?>" y1="7" x2="<?= $x+2 ?>" y2="11" class="muted-string"/><line x1="<?= $x+2 ?>" y1="7" x2="<?= $x-2 ?>" y2="11" class="muted-string"/>
<?php elseif ($value==='0'): ?><circle cx="<?= $x ?>" cy="9" r="3" class="open-string"/>
<?php elseif (ctype_digit($value)): $y=18+(int)$value*11-5; ?><circle cx="<?= $x ?>" cy="<?= $y ?>" r="4" class="finger"/><?php endif; ?>
<?php endfor; ?></svg></div>
