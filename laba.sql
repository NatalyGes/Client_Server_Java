drop table if exists task cascade ;
drop table if exists subtask cascade ;
drop table if exists tags cascade ;


create table task(
  id serial not null,
  name text not null ,
  des text null ,
  done boolean null,
  arch boolean null,
  havedate boolean null,
  data date null
);
ALTER TABLE public.task ADD PRIMARY KEY (id);

create table subtask(
  idtask int not null,
  namest text not null ,
  desst text null,
  donest boolean null,
  archst boolean null
);
/*ALTER TABLE public.subtask ADD CONSTRAINT "UQ_subtask_name" UNIQUE (idtask,name);*/

create table tags(
  idtask int not null,
  nametg text not null
);

-- ALTER TABLE public.tags ADD CONSTRAINT "UQ_tags_name" UNIQUE (idtask,name);

ALTER TABLE public.subtask ADD CONSTRAINT "FK_subtask_task_id" FOREIGN KEY (idtask)
  REFERENCES public.task (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.tags ADD CONSTRAINT "FK_tags_task_id" FOREIGN KEY (idtask)
  REFERENCES public.task (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE;

select * from task;
select * from subtask;
select * from tags;



/* 0. все ------- работает в бд*/
SELECT t.id,t.name,t.des,t.done,t.arch,t.havedate,t.data,s.namest,s.desst,s.donest,tags.nametg
FROM task t LEFT JOIN subtask s ON t.id = s.idtask LEFT JOIN tags ON tags.idtask = t.id ORDER BY id;

/*1. на ближайший месяц с тегом и описанием ------ работает в бд (берёт полное описание, а не строку в описании)*/
SELECT t.id,t.name,t.des,t.done,t.arch,t.havedate,t.data,s.name,s.des,s.done, tags.name
  FROM task t LEFT JOIN subtask s ON t.id = s.idtask LEFT JOIN tags ON t.id = tags.idtask
    WHERE t.id IN ( SELECT t.id FROM task t LEFT JOIN subtask s ON t.id = s.idtask
      LEFT JOIN tags ON t.id = tags.idtask WHERE t.arch = FALSE AND (tags.name = ?) AND (t.des = ?) AND t.data::date
        BETWEEN now() AND (now() + INTERVAL '1 MONTH')) ORDER BY t.id;


/*2. половина подзадач завершена ------ работает в бд*/
SELECT t.id, t.name, t.des, t.done, t.arch, t.havedate, t.data, s.name, s.des, s.done, tags.name
  FROM task t LEFT JOIN subtask s ON t.id = s.idtask LEFT JOIN tags ON t.id = tags.idtask
    WHERE t.id IN ( SELECT t.id FROM task t LEFT JOIN subtask s ON t.id = s.idtask LEFT JOIN tags ON t.id = tags.idtask
      WHERE t.arch = FALSE GROUP BY s.idtask, t.id HAVING avg ( coalesce(s.done::int,0 ))>= 0.5 ) ORDER BY id ;


/* 3. 3 популярных тега, просроченные ------ работает в бд*/

SELECT t.id, t.name, t.des, t.done, t.arch, t.havedate, t.data, s.name, s.des, s.done, tags.name
  FROM task t LEFT JOIN subtask s ON t.id = s.idtask LEFT JOIN tags ON t.id = tags.idtask
    WHERE t.id IN ( SELECT DISTINCT t.id FROM task t LEFT JOIN subtask s ON t.id = s.idtask LEFT JOIN tags ON t.id = tags.idtask
      WHERE t.arch = FALSE AND t.data::date BETWEEN (now() - INTERVAL '999 YEAR') AND (now() - INTERVAL '1 DAY')
        AND tags.name IN ( SELECT name FROM ( SELECT name, count(name) AS count FROM tags GROUP BY name ORDER BY count DESC LIMIT 3 ) AS sas) ) ORDER BY id;


/*4. 3 с ближайшим крайним сроком и тэгом ------ работает в бд*/

SELECT t.id, t.name, t.des, t.done, t.arch, t.havedate, t.data, s.namest, s.desst, s.donest, tags.nametg
  FROM task t LEFT JOIN subtask s ON t.id = s.idtask JOIN tags ON tags.idtask = t.id
    WHERE t.id IN ( SELECT t.id FROM task t LEFT JOIN subtask s ON t.id = s.idtask JOIN tags ON tags.idtask = t.id
      WHERE t.data IS NOT NULL AND t.data::date BETWEEN now() AND (now() + INTERVAL '999 YEAR') AND tags.nametg LIKE 'cat' AND t.arch = FALSE ORDER BY t.data) order by t.data;



/*5. 4 задачи с отдаленным крайним сроком без тэгов ------- работает в бд*/

SELECT t.id, t.name, t.des, t.done, t.arch, t.havedate, t.data, s.name, s.des, s.done, tags.name
  FROM task t LEFT JOIN subtask s ON t.id = s.idtask LEFT JOIN tags ON t.id = tags.idtask
    WHERE t.arch = FALSE AND t.data IS NOT NULL AND t.data::date BETWEEN now() AND (now() + INTERVAL '999 YEAR')
      AND tags.name IS NULL ORDER BY t.data DESC;


/*6. незавершённые задачи, отсортированные по названию по возрастанию ----- работает в бд*/

SELECT t.id, t.name, t.des, t.done, t.arch, t.havedate, t.data, s.namest, s.desst, s.donest, tags.nametg
  FROM task t LEFT JOIN subtask s ON t.id = s.idtask LEFT JOIN tags ON t.id = tags.idtask
    WHERE t.arch = FALSE AND t.done = FALSE ORDER BY t.name;

/*7. незавершённых задач, отсортированных по дате и названию по возрастанию просроченные или близ неделя  ------- работает в бд */

SELECT t.id, t.name, t.des, t.done, t.arch, t.havedate, t.data, s.name, s.des, s.done, tags.name
  FROM task t LEFT JOIN subtask s ON t.id = s.idtask LEFT JOIN tags ON t.id = tags.idtask
    WHERE t.arch = FALSE AND t.done = FALSE AND t.data::date
      BETWEEN (now() - INTERVAL '999 YEAR') AND (now()+ INTERVAL '1 WEEK') ORDER BY t.data, t.name;

/*8. незавершённых задач, отсортированных по названию по возрастанию + tag --------- работает в бд*/

SELECT t.id, t.name, t.des, t.done, t.arch, t.havedate, t.data, s.name, s.des, s.done, tags.name
  FROM task t LEFT JOIN subtask s ON t.id = s.idtask LEFT JOIN tags ON t.id = tags.idtask
    WHERE t.id IN ( SELECT t.id FROM task t LEFT JOIN subtask s ON t.id = s.idtask LEFT JOIN tags ON t.id = tags.idtask
      WHERE t.arch = FALSE AND t.done = FALSE AND tags.name LIKE 'cat' ) ORDER BY t.name;

/*9. завершённых задач, отсортированных по названию по возрастанию ------ работает в бд*/

SELECT t.id, t.name, t.des, t.Done, t.arch, t.havedate, t.data, s.name, s.des, s.done, tags.name
  FROM task t LEFT JOIN subtask s ON t.id = s.idtask LEFT JOIN tags ON t.id = tags.idtask
    WHERE t.arch = FALSE AND t.Done = TRUE ORDER BY t.name;






INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (6, 'Подзадача 4', '', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (6, 'Подзадача 3', '', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (6, 'Подзадача 2', '', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (6, 'Подзадача 1', '', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (6, 'Подзадача 5', '', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (5, 'Подзадача 3', '', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (5, 'Подзадача 1', '', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (5, 'Подзадача 2', '', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (0, 'Подзадача 2', '', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (0, 'Подзадача 1', '', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (1, 'Рыбка для котиков', 'вкусная и свежая', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (1, 'Котики', 'котята', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (1, 'Молочко', 'жирненькое', true, false);
INSERT INTO public.subtask (idtask, namest, desst, donest, archst) VALUES (2, 'Подзадача 1', '', true, false);
INSERT INTO public.tags (idtask, nametg) VALUES (5, 'artefact');
INSERT INTO public.tags (idtask, nametg) VALUES (5, 'need');
INSERT INTO public.tags (idtask, nametg) VALUES (5, 'cat');
INSERT INTO public.tags (idtask, nametg) VALUES (0, '10');
INSERT INTO public.tags (idtask, nametg) VALUES (0, 'кот');
INSERT INTO public.tags (idtask, nametg) VALUES (3, 'home');
INSERT INTO public.tags (idtask, nametg) VALUES (3, '10');
INSERT INTO public.tags (idtask, nametg) VALUES (3, 'mars');
INSERT INTO public.tags (idtask, nametg) VALUES (3, 'cat');
INSERT INTO public.tags (idtask, nametg) VALUES (1, 'кот');
INSERT INTO public.tags (idtask, nametg) VALUES (1, 'cat');
INSERT INTO public.tags (idtask, nametg) VALUES (2, 'teg');
INSERT INTO public.tags (idtask, nametg) VALUES (2, 'sun');
INSERT INTO public.tags (idtask, nametg) VALUES (2, 'cat');
INSERT INTO public.tags (idtask, nametg) VALUES (2, '10');
INSERT INTO public.task (id, name, des, done, arch, havedate, data) VALUES (6, 'Saaaaa Task', '', true, false, true, '2020-05-10');
INSERT INTO public.task (id, name, des, done, arch, havedate, data) VALUES (5, 'Артефакт', '...какой артефакт?', true, false, true, '2020-05-08');
INSERT INTO public.task (id, name, des, done, arch, havedate, data) VALUES (0, 'Тут задачи и подзадачи', 'Ну, не знаю, какое описание? Есть подзадачи там, вот. И кот', true, false, true, '2020-04-29');
INSERT INTO public.task (id, name, des, done, arch, havedate, data) VALUES (3, 'Будущий дом', 'Наш будущий дом, но и котеек не забудем взять', false, false, true, '2020-04-22');
INSERT INTO public.task (id, name, des, done, arch, havedate, data) VALUES (1, 'Про котиков', 'Есть котята, а есть котики', true, false, true, '2020-04-22');
INSERT INTO public.task (id, name, des, done, arch, havedate, data) VALUES (2, 'Задача', 'кот гуляет в огороде кот', true, false, true, '2020-05-01');
INSERT INTO public.task (id, name, des, done, arch, havedate, data) VALUES (4, 'Wat wat', '29.04.2020', true, false, true, '2020-05-10');