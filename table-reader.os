﻿#Использовать 1commands
#Использовать tempfiles

Перем мИмяФайлаБазы;
Перем мКаталогВнешнихПрограмм;
Перем мРабочийКаталог;
Перем Лог;
Перем ЭтоWindows;

Процедура ОткрытьФайл(Знач ИмяФайла) Экспорт
	мИмяФайлаБазы = ИмяФайла;
КонецПроцедуры

Процедура ЗакрытьФайл() Экспорт
	мИмяФайлаБазы = Неопределено;
	ВременныеФайлы.УдалитьФайл(мРабочийКаталог);
КонецПроцедуры

Функция ПрочитатьТаблицу(Знач ИмяТаблицы) Экспорт
	
	ВыгрузитьТаблицыВXML(ИмяТаблицы);
	
	Возврат ПрочитатьТаблицуИзXml(ФайлВыгрузкиТаблицы(ИмяТаблицы));
	
КонецФункции

Функция ВыгрузитьТаблицыВXML(Знач ИменаТаблиц) Экспорт

	ЛогTool1CD = ВременныеФайлы.НовоеИмяФайла("txt");
	ПрефиксПути = ?(ЭтоWindows = Ложь, "Z:", "");
	СтрокаЗапуска = """" + ПутьTool1CD() + """ " 
			+ """"+ ПрефиксПути + мИмяФайлаБазы + """"
			+ " -l """ +ПрефиксПути+ ЛогTool1CD + """"
			+ " -q -ne -ex " 
			+ """" + ПрефиксПути + РабочийКаталог() + """ """  + ИменаТаблиц + """";
			
	КодВозврата = "";
	Если НЕ ЭтоWindows Тогда 
		СтрокаЗапуска = "wine "+СтрокаЗапуска;
	КонецЕсли;
	Лог.Отладка(СтрокаЗапуска);
	
	Команда = Новый Команда;
	Команда.УстановитьСтрокуЗапуска(СтрокаЗапуска);
	Команда.УстановитьКодировкуВывода(КодировкаТекста.UTF8);
	Команда.ПоказыватьВыводНемедленно(Истина);
	КодВозврата = Команда.Исполнить();
		
	Если КодВозврата <> 0 Тогда
		Лог.Ошибка(Команда.ПолучитьВывод());
		ПоказатьЛог(ЛогTool1CD);
		ВызватьИсключение "Tool_1CD вернул код: " + КодВозврата;
		
	КонецЕсли;
	
	МассивИменТаблиц = РазложитьИменаТаблицВМассив(ИменаТаблиц);
	ФайлыВыгрузки = Новый Соответствие;
	Для Каждого ИмяТаблицы Из МассивИменТаблиц Цикл
		
		ФайлТаблицы = Новый Файл(ФайлВыгрузкиТаблицы(ИмяТаблицы));
		Если Не ФайлТаблицы.Существует() Тогда
			ВызватьИсключение "Таблица " + ИмяТаблицы + " не была выгружена Tool_1CD";
		КонецЕсли;
		
		ФайлыВыгрузки[ИмяТаблицы] = ФайлТаблицы.ПолноеИмя;
		
	КонецЦикла;
	
	Возврат ФайлыВыгрузки;
	
КонецФункции

Функция ПрочитатьТаблицуИзXml(Знач ФайлТаблицы) Экспорт

	ЧтениеXML = Новый ЧтениеXML;
	ЧтениеXML.ОткрытьФайл(ФайлТаблицы);
	
	Попытка
	
		ЧтениеXML.ПерейтиКСодержимому();
		ЧтениеXML.Прочитать();
		
		ПоляТаблицы = ПрочитатьПоляТаблицыИзXML(ЧтениеXML);
		ДанныеТаблицы = Новый ТаблицаЗначений;
		Для Каждого Поле Из ПоляТаблицы Цикл
			ДанныеТаблицы.Колонки.Добавить(Поле);
		КонецЦикла;
		
		Пока ЧтениеXML.Прочитать() Цикл 
			
			Если ЧтениеXML.ТипУзла = ТипУзлаXML.НачалоЭлемента 
				И ЧтениеXML.Имя = "Record" Тогда
				
				НоваяСтрока = ДанныеТаблицы.Добавить();
				Пока ЧтениеXML.Прочитать() Цикл
					Если ЧтениеXML.ТипУзла = ТипУзлаXML.НачалоЭлемента Тогда
						НоваяСтрока[ЧтениеXML.Имя] = ПолучитьТекст(ЧтениеXML);
					КонецЕсли;
					
					Если ЧтениеXML.ТипУзла = ТипУзлаXML.КонецЭлемента И ЧтениеXML.Имя = "Record" Тогда
						Прервать;	
					КонецЕсли;
				
				КонецЦикла;	
					
			КонецЕсли;
		КонецЦикла;
		
		ЧтениеXML.Закрыть();
		
	Исключение
		ЧтениеXML.Закрыть();
		ВызватьИсключение;
	КонецПопытки;
	
	Возврат ДанныеТаблицы;

КонецФункции

Функция ПрочитатьПоляТаблицыИзXML(Знач ЧтениеXML)
	ИменаПолей = Новый Массив;
	Пока ЧтениеXML.Прочитать() Цикл 
		
		Если ЧтениеXML.ТипУзла = ТипУзлаXML.НачалоЭлемента 
			И ЧтениеXML.Имя = "Field" Тогда
			
			ИменаПолей.Добавить(ЧтениеXML.ЗначениеАтрибута("Name"));
			
		КонецЕсли;
	
		Если ЧтениеXML.ТипУзла = ТипУзлаXML.КонецЭлемента И ЧтениеXML.Имя = "Fields" Тогда
			Прервать;	
		КонецЕсли;
	
	КонецЦикла;
	
	Возврат ИменаПолей;
	
КонецФункции

Функция ПолучитьТекст(ЧтениеXML)
	Результат = "";
	Пока ЧтениеXML.Прочитать()	Цикл
		
		Если ЧтениеXML.ТипУзла = ТипУзлаXML.Текст Тогда
			Результат = ЧтениеXML.Значение;
		КонецЕсли;
		Если ЧтениеXML.ТипУзла = ТипУзлаXML.КонецЭлемента Тогда
			Прервать;
		КонецЕсли;
	КонецЦикла;  
	
	Возврат Результат;
	
КонецФункции

Функция РабочийКаталог()
	Если мРабочийКаталог = Неопределено Тогда
		мРабочийКаталог = ВременныеФайлы.СоздатьКаталог();
	КонецЕсли;
	
	Возврат мРабочийКаталог;
	
КонецФункции

Функция ПутьTool1CD()
	Если мКаталогВнешнихПрограмм = Неопределено Тогда
		мКаталогВнешнихПрограмм = ОбъединитьПути(ТекущийСценарий().Каталог, "bin", "cTool_1CD.exe");
	КонецЕсли;
	
	Возврат мКаталогВнешнихПрограмм;
	
КонецФункции

Функция ФайлВыгрузкиТаблицы(Знач Таблица)
	Возврат ОбъединитьПути(РабочийКаталог(), Таблица+".xml");
КонецФункции

Процедура ПоказатьЛог(Знач ЛогTool1CD)
	ТекстЛога = ПрочитатьФайл(ЛогTool1CD);
	Сообщить(ТекстЛога);

	Попытка
		УдалитьФайлы(ЛогTool1CD);
	Исключение
	КонецПопытки;
КонецПроцедуры

Функция ПрочитатьФайл(Знач ИмяФайла)
	Чтение = Новый ЧтениеТекста(ИмяФайла);
	Текст = Чтение.Прочитать();
	Чтение.Закрыть();
	
	Возврат Текст;
КонецФункции

Функция РазложитьИменаТаблицВМассив(Знач ИменаТаблиц)
	
	МассивИмен = Новый Массив;
	Хвост = ИменаТаблиц;
	Пока Истина Цикл
		Поз = Найти(Хвост, ";");
		Если Поз > 0 Тогда
			Голова = СокрЛП(Лев(Хвост, Поз-1));
			Хвост  = Сред(Хвост, Поз+1);
			МассивИмен.Добавить(Голова);
		Иначе
			Голова = СокрЛП(Хвост);
			Если Не ПустаяСтрока(Голова) Тогда
				МассивИмен.Добавить(Голова);
			КонецЕсли;
			Прервать;
		КонецЕсли;
	КонецЦикла;
	
	Возврат МассивИмен;
	
КонецФункции

СистемнаяИнформация = Новый СистемнаяИнформация;
ЭтоWindows = Найти(НРег(СистемнаяИнформация.ВерсияОС), "windows") > 0;

Лог = Логирование.ПолучитьЛог("oscript.lib.tool1cd");