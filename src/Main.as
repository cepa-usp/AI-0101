package  
{
	import cepa.utils.ToolTip;
	import fl.transitions.easing.None;
	import fl.transitions.Tween;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import cepa.utils.HumanRandom;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	import pipwerks.SCORM;
	/**
	 * ...
	 * @author Luciano
	 */
	public class Main extends MovieClip
	{
		private var PONTOS:Array;
									 
		private const PECAS:Array = [L1C1, L1C2, L1C3, L2C1, L2C2, L2C3, L3C1, L3C2, L3C3];
		private var randomPoint:HumanRandom;
		private var ponto:Point;
		private var dragging:MovieClip;
		private var startX:Number;
		private var startY:Number;
		private var dropPoint:Point;
		private var alvo;
		private var pontuacao:int = 0;
		private var errouF1:Boolean;
		private var errouF2:Boolean;
		private var errouF3:Boolean;
		private var tweenXDragging:Tween;
		private var tweenYDragging:Tween;
		private var tweenXDrop:Tween;
		private var tweenYDrop:Tween;
		
		public function Main() 
		{
			if (stage) init(null);
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event):void 
		{
			PONTOS = [new Point(funcao1.x, funcao1.y), new Point(funcao2.x, funcao2.y), new Point(funcao3.x, funcao3.y),
			new Point(funcao4.x, funcao4.y), new Point(funcao5.x, funcao5.y), new Point(funcao6.x, funcao6.y),
			new Point(funcao7.x, funcao7.y), new Point(funcao8.x, funcao8.y), new Point(funcao9.x, funcao9.y)];
			
			removeEventListener(Event.ADDED_TO_STAGE, init);
			botoes.resetButton.addEventListener(MouseEvent.CLICK, reset);
			botoes.tutorialBtn.addEventListener(MouseEvent.CLICK, iniciaTutorial);
			entrada.botaoPlay.addEventListener(MouseEvent.CLICK, responder);
			botoes.orientacoesBtn.addEventListener(MouseEvent.CLICK, function () { infoScreen.visible = true; setChildIndex(infoScreen, numChildren - 1); } );
			infoScreen.addEventListener(MouseEvent.CLICK, function () { infoScreen.visible = false;} );
			botoes.creditos.addEventListener(MouseEvent.CLICK, function () { aboutScreen.visible = true; setChildIndex(aboutScreen, numChildren - 1); } );
			aboutScreen.addEventListener(MouseEvent.CLICK, function () { aboutScreen.visible = false;} );
			confirmacao.addEventListener(MouseEvent.CLICK, confirma);
			
			entrada.verResposta.mouseEnabled = false;
			
			confirmacao.visible = false;
			infoScreen.visible = false;
			aboutScreen.visible = false;
			entrada.verResposta.alpha = 0.3;
			
			this.scrollRect = new Rectangle(0, 0, 700, 500);
			
			addEventListeners();
			
			randomPoint = new HumanRandom(PONTOS);
			randomPoint.memory = PONTOS.length;
			
			createToolTips();
			iniciaTutorial();
			sorteiaPontos();
			
			// Inicia a conexao com o Moodle
			initLMSConnection();
		}
		
		private function createToolTips():void 
		{
			var intTT:ToolTip = new ToolTip(botoes.tutorialBtn, "Reiniciar tutorial", 12, 0.8, 150, 0.6, 0.1);
			var instTT:ToolTip = new ToolTip(botoes.orientacoesBtn, "Orientações", 12, 0.8, 100, 0.6, 0.1);
			var resetTT:ToolTip = new ToolTip(botoes.resetButton, "Reiniciar", 12, 0.8, 100, 0.6, 0.1);
			var infoTT:ToolTip = new ToolTip(botoes.creditos, "Créditos", 12, 0.8, 100, 0.6, 0.1);
			
			addChild(intTT);
			addChild(instTT);
			addChild(resetTT);
			addChild(infoTT);
		}
		
		private function verificaAtividade():void
		{
			if (completed) {
				valendo = false;
			}
		}
		
		private function resposta(e:MouseEvent):void 
		{
			entrada.botaoPlay.mouseEnabled = false;
			entrada.verResposta.mouseEnabled = false;
			entrada.verResposta.alpha = 0.3;
			entrada.botaoPlay.alpha = 0.3;
			
			funcao1.x = PONTOS[0].x;
			funcao1.y = PONTOS[0].y;
			funcao1.filters = [];
			funcao2.x = PONTOS[1].x;
			funcao2.y = PONTOS[1].y;
			funcao2.filters = [];
			funcao3.x = PONTOS[2].x;
			funcao3.y = PONTOS[2].y;
			funcao3.filters = [];
			funcao4.x = PONTOS[3].x;
			funcao4.y = PONTOS[3].y;
			funcao4.filters = [];
			funcao5.x = PONTOS[4].x;
			funcao5.y = PONTOS[4].y;
			funcao5.filters = [];
			funcao6.x = PONTOS[5].x;
			funcao6.y = PONTOS[5].y;
			funcao6.filters = [];
			funcao7.x = PONTOS[6].x;
			funcao7.y = PONTOS[6].y;
			funcao7.filters = [];
			funcao8.x = PONTOS[7].x;
			funcao8.y = PONTOS[7].y;
			funcao8.filters = [];
			funcao9.x = PONTOS[8].x;
			funcao9.y = PONTOS[8].y;
			funcao9.filters = [];
		}
		
		private function confirma(e:MouseEvent):void 
		{
			valendo = true;
			confirmacao.visible = false;
			scormExercise = 1;
			reset(null);
		}
		
		private const GLOW_FILTER:GlowFilter = new GlowFilter(0x008000, 1, 6, 6, 2, 20);
		
		private function onMouseMove(e:MouseEvent):void 
		{	
			alvo = null;
			
			var peca:DisplayObject;
			
			for (var i:int = 1; i <= 9; i++) {
				
				peca = this["funcao" + i];
				if (peca == dragging) continue;
				
				if (peca.hitTestPoint(dragging.x, dragging.y, true)) {
					if (peca.filters.length == 0) peca.filters = [GLOW_FILTER];
					setChildIndex(peca, Math.max(0, getChildIndex(dragging) - 1));
					alvo = peca;
				} else {
					peca.filters = [];
				}
			}
		}
		
		private function responder(e:MouseEvent):void 
		{
			pontuacao = 0;
			entrada.verResposta.alpha = 1;
			entrada.verResposta.mouseEnabled = true;
			entrada.verResposta.removeEventListener(MouseEvent.CLICK, resposta);
			entrada.verResposta.addEventListener(MouseEvent.CLICK, resposta);
			
			for (var i:int = 1; i <= 9; i++) this["funcao" + String(i)].filters = null;
			errouF1 = errouF2 = errouF3 = false;
			
			// Verifica se cada uma das 3 funções se encontram em alguma das colunas da PRIMEIRA linha
			if ((funcao1.x == PONTOS[0].x && funcao1.y == PONTOS[0].y) || (funcao1.x == PONTOS[1].x && funcao1.y == PONTOS[1].y) || (funcao1.x == PONTOS[2].x && funcao1.y == PONTOS[2].y)) pontuacao++;
			else {
				errouF1 = true;
				funcao1.filters = [new GlowFilter(0xFF0000, 1, 6, 6, 2, 20)];
			}
			if ((funcao2.x == PONTOS[0].x && funcao2.y == PONTOS[0].y) || (funcao2.x == PONTOS[1].x && funcao2.y == PONTOS[1].y) || (funcao2.x == PONTOS[2].x && funcao2.y == PONTOS[2].y)) pontuacao++;
			else {
				errouF2 = true;
				funcao2.filters = [new GlowFilter(0xFF0000, 1, 6, 6, 2, 20)];
			}
			if ((funcao3.x == PONTOS[0].x && funcao3.y == PONTOS[0].y) || (funcao3.x == PONTOS[1].x && funcao3.y == PONTOS[1].y) || (funcao3.x == PONTOS[2].x && funcao3.y == PONTOS[2].y)) pontuacao++;
			else {
				errouF3 = true;
				funcao3.filters = [new GlowFilter(0xFF0000, 1, 6, 6, 2, 20)];
			}
			
			// Verifica se as primeiras derivadas estão nas colunas corretas
			if (!errouF1 && funcao4.x == funcao1.x && funcao4.y == PONTOS[3].y) pontuacao++;
			else funcao4.filters = [new GlowFilter(0xFF0000, 1, 6, 6, 2, 20)];
			if (!errouF2 && funcao5.x == funcao2.x && funcao5.y == PONTOS[4].y) pontuacao++;
			else funcao5.filters = [new GlowFilter(0xFF0000, 1, 6, 6, 2, 20)];
			if (!errouF3 && funcao6.x == funcao3.x && funcao6.y == PONTOS[5].y) pontuacao++;
			else funcao6.filters = [new GlowFilter(0xFF0000, 1, 6, 6, 2, 20)];
			
			// Verifica se as segundas derivadas estão nas colunas corretas
			if (!errouF1 && funcao7.x == funcao1.x && funcao7.y == PONTOS[6].y) pontuacao++;
			else funcao7.filters = [new GlowFilter(0xFF0000, 1, 6, 6, 2, 20)];
			if (!errouF2 && funcao8.x == funcao2.x && funcao8.y == PONTOS[7].y) pontuacao++;
			else funcao8.filters = [new GlowFilter(0xFF0000, 1, 6, 6, 2, 20)];
			if (!errouF3 && funcao9.x == funcao3.x && funcao9.y == PONTOS[8].y) pontuacao++;
			else funcao9.filters = [new GlowFilter(0xFF0000, 1, 6, 6, 2, 20)];
			
			pontuacao = Math.round(pontuacao * (100 / 9));
			
			entrada.pontuacao_tf.text = String(pontuacao);
			
			entrada.verResposta.alpha = 1;
			entrada.verResposta.mouseEnabled = true;
			
			if (valendo && !completed) {
				score = pontuacao;
				completed = true;
				save2LMS();
			}
		}
		
		private function addEventListeners():void
		{
			for (var i:int = 1; i <= 9; i++) {
				this["funcao" + String(i)].addEventListener(MouseEvent.MOUSE_DOWN, drag);
				//this["funcao" + String(i)].addEventListener(MouseEvent.MOUSE_UP, drop);
			}
		}
		
		private function drag(e:MouseEvent):void 
		{
			if (tweenXDragging == null || !tweenXDragging.isPlaying)
			{
				dragging = e.currentTarget as MovieClip;
				setChildIndex(dragging, numChildren - 1);
				setChildIndex(entrada, numChildren - 1);
				setChildIndex(balao, numChildren - 1);
				startX = dragging.x;
				startY = dragging.y;
				dragging.startDrag();
				addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				stage.addEventListener(MouseEvent.MOUSE_UP, drop);
			}
		}
		
		private function drop(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, drop);
			removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			dragging.stopDrag();
			
			for (var i:int = 1; i <= 9; i++) {
				this["funcao" + String(i)].filters = [];
			}
			
			//alvo = e.target.dropTarget;
			
			//trace(dragging.x, dragging.y);
			
/*			if (dragging.x >= 65 && dragging.x <= 255 && dragging.y >= 49 && dragging.y <= 189) {
				dropPoint = new Point(165, 124);
			}
			else if (dragging.x >= 255 && dragging.x <= 455 && dragging.y >= 49 && dragging.y <= 189) {
				dropPoint = new Point(320, 124);
			}
			else if (dragging.x >= 455 && dragging.x <= 665 && dragging.y >= 49 && dragging.y <= 189) {
				dropPoint = new Point(475, 124);
			}
			else if (dragging.x >= 65 && dragging.x <= 255 && dragging.y >= 155 && dragging.y <= 305) {
				dropPoint = new Point(165, 240);
			}
			else if (dragging.x >= 255 && dragging.x <= 455 && dragging.y >= 155 && dragging.y <= 305) {
				dropPoint = new Point(320, 240);
			}
			else if (dragging.x >= 455 && dragging.x <= 665 && dragging.y >= 155 && dragging.y <= 305) {
				dropPoint = new Point(475, 240);
			}
			else if (dragging.x >= 65 && dragging.x <= 255 && dragging.y >= 230 && dragging.y <= 380) {
				dropPoint = new Point(165, 356);
			}
			else if (dragging.x >= 255 && dragging.x <= 455 && dragging.y >= 230 && dragging.y <= 380) {
				dropPoint = new Point(320, 356);
			}
			else if (dragging.x >= 455 && dragging.x <= 665 && dragging.y >= 230 && dragging.y <= 380) {
				dropPoint = new Point(475, 356);
			} else {
				dropPoint = new Point(startX, startY);
			}
			
			for (var i:int = 0; i < 9; i++) if (this["funcao" + String(i + 1)].x == dropPoint.x && this["funcao" + String(i + 1)].y == dropPoint.y) alvo = this["funcao" + String(i + 1)];
*/
			//dropPoint = new Point(alvo.x, alvo.y);
			
			dropTween();
		}
		
		private function dropTween():void
		{
			if (alvo == null) {
				tweenXDragging = new Tween(dragging, "x", None.easeNone, dragging.x, startX, 0.3, true);
				tweenYDragging = new Tween(dragging, "y", None.easeNone, dragging.y, startY, 0.3, true);
				return;
			}
			
			tweenXDragging = new Tween(dragging, "x", None.easeNone, dragging.x, alvo.x, 0.3, true);
			tweenYDragging = new Tween(dragging, "y", None.easeNone, dragging.y, alvo.y, 0.3, true);
			
			tweenXDrop = new Tween(alvo, "x", None.easeNone, alvo.x, startX, 0.3, true);
			tweenYDrop = new Tween(alvo, "y", None.easeNone, alvo.y, startY, 0.3, true);
			
			dragging = null;
			//dropPoint = null;
		}
		
		private function reset(e:MouseEvent):void 
		{
			entrada.verResposta.removeEventListener(MouseEvent.CLICK, resposta);
			entrada.verResposta.alpha = 1;
			randomPoint = new HumanRandom(PONTOS);
			randomPoint.memory = PONTOS.length;
			entrada.verResposta.alpha = 0.3;
			entrada.verResposta.mouseEnabled = false;
			pontuacao = 0;
			entrada.pontuacao_tf.text = "0";
			entrada.botaoPlay.mouseEnabled = true;
			entrada.botaoPlay.alpha = 1;
			sorteiaPontos();
		}
		
		private function sorteiaPontos():void
		{
			for (var i:int = 1; i <= 9; i++) {
				ponto = randomPoint.getItem();
				this["funcao" + String(i)].x = ponto.x;
				this["funcao" + String(i)].y = ponto.y;
				this["funcao" + String(i)].filters = null;
			}
		}
		
		// VARIAVEIS SCORM
		private const PING_INTERVAL:Number = 5 * 60 * 1000; // 5 minutos
		private var completed:Boolean;
		private var scorm:SCORM;
		private var scormExercise:int;
		private var connected:Boolean;
		private var score:int;
		private var pingTimer:Timer;
		private var valendo:Boolean;
		
		/**
		 * @private
		 * Inicia a conexão com o LMS.
		 */
		private function initLMSConnection () : void
		{
			completed = false;
			connected = false;
			scorm = new SCORM();
			
			connected = scorm.connect();
			
			if (connected) {
				
				// Verifica se a AI já foi concluída.
				var status:String = scorm.get("cmi.completion_status");				
			 
				switch(status)
				{
					// Primeiro acesso à AI
					case "not attempted":
					case "unknown":
					default:
						completed = false;
						scormExercise = 0;
						score = 0;
						break;
					
					// Continuando a AI...
					case "incomplete":
						completed = false;
						
						scormExercise = int(scorm.get("cmi.location"));
						if (isNaN(scormExercise)) scormExercise = 0;
						
						score = int(scorm.get("cmi.score.raw"));
						if (isNaN(score)) score = 0;
						
						break;
					
					// A AI já foi completada.
					case "completed":
						completed = true;
						
						scormExercise = int(scorm.get("cmi.location"));
						if (isNaN(scormExercise)) scormExercise = 0;
						
						score = int(scorm.get("cmi.score.raw"));
						if (isNaN(score)) score = 0;
						
						setMessage("ATENÇÃO: esta Atividade Interativa já foi completada. Você pode refazê-la quantas vezes quiser, mas não valerá nota.");
						break;
				}
				
				var success:Boolean = scorm.set("cmi.score.min", "0");
				if (success) success = scorm.set("cmi.score.max", "100");
				
				if (success)
				{
					scorm.save();
					pingTimer.start();
				}
				else
				{
					//trace("Falha ao enviar dados para o LMS.");
					connected = false;
				}
			}
			else
			{
				setMessage("Esta Atividade Interativa não está conectada a um LMS: seu aproveitamento nela NÃO será salvo.");
			}
			
		}
		
		/**
		 * @private
		 * Salva cmi.score.raw, cmi.location e cmi.completion_status no LMS
		 */ 
		private function save2LMS ()
		{
			if (connected)
			{
				// Salva no LMS a nota do aluno.
				var success:Boolean = scorm.set("cmi.score.raw", score.toString());

				// Notifica o LMS que esta atividade foi concluída.
				success = scorm.set("cmi.completion_status", (completed ? "completed" : "incomplete"));

				// Salva no LMS o exercício que deve ser exibido quando a AI for acessada novamente.
				success = scorm.set("cmi.location", scormExercise.toString());

				if (success)
				{
					scorm.save();
				}
				else
				{
					pingTimer.stop();
					setMessage("Falha na conexão com o LMS.");
					connected = false;
				}
			}
		}
		
		/**
		 * @private
		 * Mantém a conexão com LMS ativa, atualizando a variável cmi.session_time
		 */
		private function pingLMS (event:TimerEvent)
		{
			scorm.get("cmi.completion_status");
		}
		
		private function setMessage (message:String = null) : void
		{
			if (message)
			{
			}
			else
			{
			}
		}
		
//Tutorial
		private var posQuadradoArraste:Point = new Point();
		private var balao:CaixaTexto;
		private var pointsTuto:Array;
		private var tutoBaloonPos:Array;
		private var tutoPos:int;
		private var tutoSequence:Array = ["O objetivo desta atividade é relacionar corretamente as funções com suas derivadas.",
										  "Há três funções f(x) diferentes e você deve identificá-las, bem como suas duas primeiras derivadas, f'(x) e f''(x).",
										  "Na primeira linha você deve colocar as funções, f(x).",
										  "Na segunda linha você deve colocar as derivadas de primeira ordem, f'(x), imediatamente abaixo da função que deu origem a ela.",
										  "Finalmente, na terceira linha você deve colocar as derivadas de ordem dois, f''(x).",
										  "Quando você tiver concluído, pressione o botão \"terminei\" para verificar sua resposta.",
										  "As peças destacadas em vermelho estão erradas; aquelas em verde estão corretas.",
										  "Você pode tentar quantas vezes quiser, basta pressionar em \"novo exercício\"."];
		
		/**
		 * Inicia o tutorial da atividade.
		 */								  
		private function iniciaTutorial(e:MouseEvent = null):void 
		{
			tutoPos = 0;
			if(balao == null){
				balao = new CaixaTexto(true);
				addChild(balao);
				setChildIndex(balao, numChildren - 1);
				balao.visible = false;
				
				pointsTuto = 	[new Point(250, 170),
								new Point(250, 270),
								new Point(250, 270),
								new Point(250, 270),
								new Point(250, 270),
								new Point(250, 270),
								new Point(250, 270),
								new Point(435, 270)];
								
				tutoBaloonPos = [["", ""],
								[CaixaTexto.LEFT, CaixaTexto.CENTER],
								[CaixaTexto.LEFT, CaixaTexto.CENTER],
								[CaixaTexto.LEFT, CaixaTexto.CENTER],
								[CaixaTexto.LEFT, CaixaTexto.CENTER],
								[CaixaTexto.LEFT, CaixaTexto.CENTER],
								[CaixaTexto.LEFT, CaixaTexto.CENTER],
								[CaixaTexto.TOP, CaixaTexto.FIRST]];
			}
			
			balao.removeEventListener(Event.CLOSE, closeBalao);
			balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
			balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			balao.addEventListener(Event.CLOSE, closeBalao);
			balao.visible = true;
		}
		
		private function closeBalao(e:Event):void 
		{
			tutoPos++;
			if (tutoPos >= tutoSequence.length) {
				balao.removeEventListener(Event.CLOSE, closeBalao);
				balao.visible = false;
			}else {
				balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
				balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			}
		}
	}

}