-- Aktiv polislərin sayını sığorta növünə görə çıxarın.
SELECT 
    sigorta_novu,
    COUNT(polis_id) AS polis_sayi
FROM polisler
WHERE status = 'Aktiv'
GROUP BY sigorta_novu
ORDER BY polis_sayi DESC; 

-- Bakı şəhərindən olan qadın müştərilərin siyahısını yaşa görə
 -- azalan sırada göstərin.
 
SELECT
	 musteri_id,
     ad,
	TIMESTAMPDIFF(YEAR, dogum_tarixi, CURDATE()) AS yas
from musteriler
where cins='qadın'
order by yas desc

-- Hər sığorta növü üzrə orta illik premium nə qədərdir? 
-- Yalnız orta premiumu 1000-dən yüksək olanları göstərin.

SELECT 
    sigorta_novu,
    AVG(coalesce(illik_premium,0)) AS orta_premium
FROM polisler
GROUP BY sigorta_novu
HAVING AVG(illik_premium) > 1000;

-- Ləğv edilib statuslu polislərin ümumi sığorta məbləğini tapın.

SELECT 
    status,
    COUNT(*) AS polis_sayi,
    SUM(sigorta_meblegi) AS umumi_mebleg
FROM polisler
WHERE status = 'Ləğv edilib'
GROUP BY status;
 
--  Ödəniş üsullarına görə (Kart / Köçürmə / Nağd) 
--  ödənişlərin sayını və payını (%) hesablayın.

SELECT 
    odenis_usulu,
    COUNT(*) AS odenis_sayi,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pay_faiz
FROM odenisler
GROUP BY odenis_usulu
ORDER BY odenis_sayi DESC;

-- Hər agent üzrə satdığı polislərin 
-- sayını və ümumi premiumunu göstərin. 
-- Agentin adı və filialı da olsun.

SELECT
    a.agent_adi,
    a.filial,
    count(p.polis_id) as 'Polis_sayi' ,
    coalesce(sum(p.illik_premium),0) as 'Total_Premium'
from agentler a 
left join polisler p on a.agent_id=p.agent_id
group by  a.agent_id,a.agent_adi , a.filial
order by Total_Premium desc

-- Heç bir polisi olmayan müştərilər varmı? 
-- Varsa, siyahını verin.

select 
	m.musteri_id,
    m.ad,
    m.soyad
from musteriler m
where NOT EXISTS ( 
select 1
from polisler p 
where p.musteri_id=m.musteri_id)

-- Hər filial üzrə iddia sayını 
-- və rədd edilmiş iddiaların faizini tapın.

select
    a.filial,
    count(*) as iddia_sayi,
    SUM(i.status = 'Rədd edilib') AS redd_sayi,
    ROUND(SUM(i.status = 'Rədd edilib') * 100.0 / COUNT(*), 2) AS redd_faiz
from agentler a
join polisler p on a.agent_id=p.agent_id
Join iddialar i on p.polis_id=i.polis_id
group by a.filial

-- Ən azı 2 gecikmiş ödənişi 
-- (gecikme_gun > 0) olan müştəriləri tapın.


 SELECT 
    m.musteri_id,
    m.ad,
    m.soyad,
    COUNT(*) AS gecikmis_odenis_sayi
FROM odenisler o
JOIN polisler p ON o.polis_id = p.polis_id
JOIN musteriler m ON p.musteri_id = m.musteri_id
WHERE o.gecikme_gun > 0
GROUP BY m.musteri_id, m.ad, m.soyad
HAVING COUNT(*) >= 2
ORDER BY gecikmis_odenis_sayi DESC;



-- Hər şəhər üzrə müştəri sayını və 
-- adambaşına düşən orta illik premiumu hesablayın.

SELECT 
    m.seher,
    COUNT(DISTINCT m.musteri_id) AS musteri_sayi,
    ROUND(SUM(p.illik_premium) / COUNT(DISTINCT m.musteri_id), 2) AS adambasi_premium,
    ROUND(AVG(p.illik_premium), 2) AS polis_basi_orta_premium
FROM musteriler m
JOIN polisler p ON m.musteri_id = p.musteri_id
GROUP BY m.seher
ORDER BY adambasi_premium DESC;


-- İddia üzrə tələb olunan məbləğlə ödənilən məbləğ 
-- arasındakı fərqi hadisə növünə görə göstərin. 
-- odenilen_mebleg 
-- NULL olanda nə baş verir və bunu necə idarə edirsiniz?

SELECT 
    hadise_novu,
    SUM(teleb_olunan_mebleg) AS teleb_cemi,
    SUM(odenilen_mebleg) AS odenilen_cemi,
    SUM(teleb_olunan_mebleg) - SUM(odenilen_mebleg) AS ferq
FROM iddialar
WHERE status IN ('Ödənilib', 'Rədd edilib')
GROUP BY hadise_novu
ORDER BY ferq DESC;

-- Hər filialda ən çox premium toplayan agenti tapın.

with name1 as(
SELECT 
   a.agent_id,
   a.agent_adi,
   a.filial,
   sum(p.illik_premium) as Total_premium,
   rank() over(partition by a.filial order by sum(p.illik_premium) desc) as rnk
from agentler a
left join polisler p on a.agent_id=p.agent_id
group by a.agent_id,a.agent_adi,a.filial
)
select 
	agent_id,
    agent_adi,
    filial,
    Total_premium
from name1
where rnk=1

-- Hər müştərinin ödənişlərinin kumulativ cəmini tarix üzrə hesablayın.

 select
	m.musteri_id,
    m.ad,
    m.soyad,
    o.odenis_tarixi,
    sum(o.mebleg) over(partition by m.musteri_id order by o.odenis_tarixi , o.odenis_id 
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW  ) as kumilativ
from musteriler m
left join polisler p on m.musteri_id=p.musteri_id
left join odenisler o on p.polis_id=o.polis_id



-- Aylıq ümumi ödəniş məbləğini və əvvəlki aya nisbətən dəyişməni (%) çıxarın (LAG).

with name2 as(
SELECT 
    DATE_FORMAT(odenis_tarixi, '%Y-%m') as ay,
    sum(mebleg) as ayliq_mebleg
from odenisler
group by ay
), name3 AS (
    SELECT 
        ay,
        ayliq_mebleg,
        LAG(ayliq_mebleg) OVER (ORDER BY ay) AS evvelki_mebleg
    FROM name2
 )   
select 
   ay,
   ayliq_mebleg,
   evvelki_mebleg,
   Round((ayliq_mebleg - evvelki_mebleg )* 100 / NULLIF( evvelki_mebleg , 0) ,2) as deyisme_faiz
from name3

-- Hər polis üçün iddia tarixi ilə polisin başlama tarixi 
-- arasındakı gün fərqini tapın. Polisin ilk 
-- 30 günündə verilən iddialar şübhəli sayılsa, bunları necə filtrlərdiniz?

select
    i.iddia_id,
    p.baslama_tarixi,
    i.iddia_tarixi,
    datediff(i.iddia_tarixi,p.baslama_tarixi) as gun_ferqi
from iddialar i
join polisler p on i.polis_id=p.polis_id
where datediff(i.iddia_tarixi,p.baslama_tarixi)<=30
order by gun_ferqi asc

-- İddia verməyən müştərilərlə iddia verənlərin orta premiumunu müqayisə edin.

WITH musteri_qrup AS (
    SELECT 
        m.musteri_id,
        SUM(p.illik_premium) AS umumi_premium,
        CASE 
            WHEN EXISTS (
                SELECT 1
                FROM iddialar i
                JOIN polisler p2 ON i.polis_id = p2.polis_id
                WHERE p2.musteri_id = m.musteri_id
            ) THEN 'iddia_verib'
            ELSE 'iddia_verməyib'
        END AS qrup
    FROM musteriler m
    JOIN polisler p ON m.musteri_id = p.musteri_id
    GROUP BY m.musteri_id
)
SELECT 
    ROUND(AVG(CASE WHEN qrup = 'iddia_verməyib' THEN umumi_premium END), 2) AS orta_no_iddia,
    ROUND(AVG(CASE WHEN qrup = 'iddia_verib'    THEN umumi_premium END), 2) AS orta_with_iddia
FROM musteri_qrup;
    


   
   
    