# Kap – zakazivanje dobrovoljnog davanja krvi

Kap je sistem za zakazivanje dobrovoljnog davanja krvi. Davaoci preko mobilne aplikacije pregledaju akcije davanja krvi u svom gradu, zakazuju termin u slobodnom slotu i prate kada ponovo smeju da daju krv. Medicinsko osoblje u backoffice aplikaciji vodi dnevni raspored akcije, prima davaoce i beleži ishod pregleda, a koordinator objavljuje akcije i ažurira zalihe krvi. Akcije po gradovima i zalihe krvi po krvnim grupama javno su dostupne na vebu.

Sistem pokriva zakazivanje i prijem davalaca na akciji, a ne laboratorijsku obradu krvi niti bolničku evidenciju.

## Tim

| Ime i prezime | Broj indeksa | GitHub nalog |
|---|---|---|
| Ilija Živadinović | SI 126/24 | [@IlijaZiv](https://github.com/IlijaZiv) |

## Zahtevi za temu

**1. Uloge.** Sistem koriste davaoci, medicinsko osoblje i koordinator akcija. Davalac upravlja samo svojim terminima i profilom. Medicinsko osoblje na akciji na kojoj radi prima davaoce i beleži ishod pregleda. Koordinator objavljuje akcije, određuje slotove i kapacitet i ažurira zalihe krvi.

**2. Stanja.** Glavni pojam je termin davanja. Davalac ga zakazuje i tada je *zakazan*, a dan pre akcije davalac ga *potvrđuje*. Na akciji osoblje beleži da je davalac *pristupio*, a posle pregleda da je *dao krv* ili da je *odbijen na pregledu*. Termin može biti i *otkazan* (otkazao ga je davalac ili koordinator) ili *nije se pojavio*, ako davalac nije došao.

**3. Pravila.** Davalac mora imati između 18 i 65 godina. Između dva davanja mora proći najmanje 3 meseca za muškarce, odnosno 4 meseca za žene. Davalac može imati samo jedan aktivan termin. Termin se otkazuje najkasnije 12 sati pre početka. Svaki polusatni slot na akciji ima ograničen broj mesta. Kapacitet zavisi od termina drugih davalaca, pa kada se dvojica istovremeno prijave za poslednje mesto, konačno odlučuje server.

**4. Rad bez mreže.** Davalac i bez signala vidi svoje termine, njihova stanja i datum kada ponovo sme da da krv. Bez mreže može da otkaže termin i da popuni upitnik pre pregleda. Izmene se šalju serveru kada se veza vrati, a server ponovo proverava pravilo o roku za otkazivanje.

**5. Posao za osoblje.** Osoblje u backoffice-u radi sa dnevnim rasporedom cele akcije: svi slotovi i svi zakazani davaoci istovremeno, uz prijem po redu dolaska i brz unos ishoda pregleda. Koordinator u tabeli prati popunjenost akcija po gradovima i ažurira zalihe po krvnim grupama. Za takav posao potreban je veći ekran.

**6. Javni sadržaj.** Bez prijave svako može da pogleda predstojeće akcije po gradovima, sa adresom, datumom i brojem slobodnih mesta, kao i „semafor“ zaliha krvi po krvnim grupama. Ove stranice ljudi traže na pretraživačima, na primer „davanje krvi Beograd ova nedelja“ ili „nedostaje krvna grupa 0−“, pa ima smisla da budu vidljive pretraživačima.

Delovi sistema

Mobilna aplikacija je za davaoce, pravi se u Flutteru i radi na Androidu i iOS-u.
Backoffice je za medicinsko osoblje i koordinatora, pravi se u Flutteru i radi na Windowsu i vebu.
Javni veb je za sve posetioce, pravi se u Jaspr-u i radi u pregledaču.
Server služi ostalim delovima sistema, koristi Relic i PostgreSQL i radi na Linuxu i Windowsu.
Domenski paket koriste svi delovi sistema, pisan je u Dartu i radi svuda.

Svi delovi koriste isti domenski paket, u kome su model, stanja i pravila. Server čuva podatke i ponovo proverava svako pravilo.
