package  
{
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
		private const PONTOS:Array = [new Point(165, 124), new Point(320, 124), new Point(475, 124),
									  new Point(165, 240), new Point(320, 240), new Point(475, 240),
									  new Point(165, 356), new Point(320, 356), new Point(475, 356)];
									 
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
			removeEventListener(Event.ADDED_TO_STAGE, init);
			botaoReset.addEventListener(MouseEvent.CLICK, reset);
			menuBar.botaoPlay.addEventListener(MouseEvent.CLICK, responder);
			menuBar.verResposta.addEventListener(MouseEvent.CLICK, resposta);
			botaoInfo.addEventListener(MouseEvent.CLICK, function () { infoScreen.visible = true; setChildIndex(infoScreen, numChildren - 1); } );
			infoScreen.addEventListener(MouseEvent.CLICK, function () { infoScreen.visible = false;} );
			botaoAbout.addEventListener(MouseEvent.CLICK, function () { aboutScreen.visible = true; setChildIndex(aboutScreen, numChildren - 1); } );
			aboutScreen.addEventListener(MouseEvent.CLICK, function () { aboutScreen.visible = false;} );
			menuBar.valendoNota.addEventListener(MouseEvent.CLICK, function () { confirmacao.visible = true; menuBar.verResposta.visible = false;  setChildIndex(confirmacao, numChildren - 1); } );
			confirmacao.addEventListener(MouseEvent.CLICK, confirma);
			menuBar.upDown.addEventListener(MouseEvent.CLICK, escondeMenu);
			addEventListener(MouseEvent.MOUSE_DOWN, function () {setChildIndex(menuBar, numChildren - 1);});
			
			confirmacao.visible = false;
			infoScreen.visible = false;
			aboutScreen.visible = false;
			menuBar.verResposta.visible = false;
			
			setChildIndex(menuBar, numChildren - 1);
			
			this.scrollRect = new Rectangle(0, 0, 640, 480);
			
			addEventListeners();
			
			randomPoint = new HumanRandom(PONTOS);
			randomPoint.memory = PONTOS.length;
			
			sorteiaPontos();
			
			pingTimer = new Timer(PING_INTERVAL);
			pingTimer.addEventListener(TimerEvent.TIMER, pingLMS);
			
			// Inicia a conexao com o Moodle
			initLMSConnection();
			
			// Verifica se a atividade já foi completa ou não
			verificaAtividade();
		}
		
		private function escondeMenu(e:MouseEvent):void 
		{
			if (menuBar.y < 450) var tweenYmenu = new Tween(menuBar, "y", None.easeNone, menuBar.y, 475, 0.3, true);
			else tweenYmenu = new Tween(menuBar, "y", None.easeNone, menuBar.y, 442, 0.3, true);
			
			menuBar.upDown.seta.scaleY = menuBar.upDown.seta.scaleY * -1;
		}
		
		private function verificaAtividade():void
		{
			if (completed) {
				valendo = false;
				menuBar.valendoNota.visible = false;
			}
		}
		
		private function resposta(e:MouseEvent):void 
		{
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
			if (e.target.name == "sim") {
				valendo = true;
				menuBar.valendoNota.visible = false;
				confirmacao.visible = false;
				scormExercise = 1;
				reset(null);
			} else if (e.target.name == "nao") {
				valendo = false;
				menuBar.valendoNota.visible = true;
				confirmacao.visible = false;
			}
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
			menuBar.verResposta.visible = false;
			
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
			
			pontuacao = Math.round(pontuacao * (10 / 9));
			
			menuBar.pontuacao_tf.text = String(pontuacao);
			
			menuBar.verResposta.visible = true;
			
			if (valendo) {
				score = pontuacao * 10;
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
			randomPoint = new HumanRandom(PONTOS);
			randomPoint.memory = PONTOS.length;
			menuBar.verResposta.visible = false;
			pontuacao = 0;
			menuBar.pontuacao_tf.text = "0";
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
			if (connected)
			{
				var success:Boolean = scorm.set("cmi.session_time", Math.round(pingTimer.currentCount * PING_INTERVAL / 1000).toString());
				
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
		
		private function setMessage (message:String = null) : void
		{
			if (message)
			{
			}
			else
			{
			}
		}
	}

}